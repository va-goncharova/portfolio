CREATE TABLE IF NOT EXISTS Books (
    BookId SERIAL PRIMARY KEY,
    Title VARCHAR(200),
    Author VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS Inventory (
    BookId INT PRIMARY KEY REFERENCES Books(BookId) ON DELETE CASCADE,
    Quantity INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS BooksHistory (
    HistoryId SERIAL PRIMARY KEY,
    BookId INT REFERENCES Books(BookId) ON DELETE CASCADE,
    Title VARCHAR(200),
    Author VARCHAR(100),
    AddedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Расчет стоимости с прогрессивной скидкой
CREATE OR REPLACE FUNCTION calculate_book_price(
    p_base_price DECIMAL,
    p_quantity INT
)
RETURNS DECIMAL
LANGUAGE plpgsql
AS $$
DECLARE
    v_discount_rate DECIMAL;
    v_final_price DECIMAL;
BEGIN
    -- Прогрессивная скидка: чем больше книг, тем выше скидка
    IF p_quantity >= 100 THEN
        v_discount_rate := 0.20;
    ELSIF p_quantity >= 50 THEN
        v_discount_rate := 0.15;
    ELSIF p_quantity >= 20 THEN
        v_discount_rate := 0.10;
    ELSIF p_quantity >= 10 THEN
        v_discount_rate := 0.05;
    ELSE
        v_discount_rate := 0;
    END IF;
    
    v_final_price := p_base_price * p_quantity * (1 - v_discount_rate);
    RETURN ROUND(v_final_price, 2);
END;
$$;


SELECT 
    quantity,
    calculate_book_price(500, quantity) AS total_with_discount
FROM (VALUES (1), (5), (10), (20), (50), (100)) AS t(quantity);


-- Статистика по книге
CREATE OR REPLACE FUNCTION get_book_stats(
    IN p_book_id INT,
    OUT available_quantity INT,
    OUT total_additions INT,
    OUT last_added TIMESTAMP,
    OUT is_available BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Получаем текущее количество
    SELECT Quantity INTO available_quantity
    FROM Inventory
    WHERE BookId = p_book_id;
    
    -- Получаем статистику по истории
    SELECT 
        COUNT(*),
        MAX(AddedDate)
    INTO total_additions, last_added
    FROM BooksHistory
    WHERE BookId = p_book_id;
    
    -- Обработка NULL
    available_quantity := COALESCE(available_quantity, 0);
    total_additions := COALESCE(total_additions, 0);
    is_available := (available_quantity > 0);
END;
$$;

SELECT * FROM get_book_stats(1);


-- Топ книг
CREATE OR REPLACE FUNCTION get_top_books(
    p_min_quantity INT DEFAULT 0,
    p_limit INT DEFAULT 10
)
RETURNS TABLE(
    book_id INT,
    title VARCHAR,
    author VARCHAR,
    quantity INT,
    times_added BIGINT,
    rank_position BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.BookId,
        b.Title,
        b.Author,
        COALESCE(i.Quantity, 0) AS quantity,
        COUNT(h.HistoryId) AS times_added,
        ROW_NUMBER() OVER (ORDER BY COALESCE(i.Quantity, 0) DESC) AS rank_position
    FROM Books b
    LEFT JOIN Inventory i ON b.BookId = i.BookId
    LEFT JOIN BooksHistory h ON b.BookId = h.BookId
    GROUP BY b.BookId, b.Title, b.Author, i.Quantity
    HAVING COALESCE(i.Quantity, 0) >= p_min_quantity
    ORDER BY quantity DESC
    LIMIT p_limit;
END;
$$;

SELECT * FROM get_top_books(3, 5);
SELECT * FROM get_top_books(0, 10);  


-- Архивация старых записей
CREATE OR REPLACE PROCEDURE archive_old_history(
    p_days_old INT DEFAULT 365,
    INOUT p_archived_count INT DEFAULT 0
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_history_record RECORD;
    v_cursor CURSOR FOR
        SELECT HistoryId, BookId, Title, Author, AddedDate
        FROM BooksHistory
        WHERE AddedDate < CURRENT_DATE - p_days_old;
BEGIN
    p_archived_count := 0;
    
    FOR v_history_record IN v_cursor LOOP
        -- Вставка в архивную таблицу (временную)
        CREATE TEMP TABLE IF NOT EXISTS temp_archive AS
        SELECT * FROM BooksHistory WHERE false;
        
        INSERT INTO temp_archive (HistoryId, BookId, Title, Author, AddedDate)
        VALUES (v_history_record.HistoryId, v_history_record.BookId, 
                v_history_record.Title, v_history_record.Author, v_history_record.AddedDate);
        
        -- Удаление из основной таблицы
        DELETE FROM BooksHistory WHERE HistoryId = v_history_record.HistoryId;
        
        p_archived_count := p_archived_count + 1;
    END LOOP;
    
    RAISE NOTICE 'Архивировано записей истории: %', p_archived_count;
    
    IF p_archived_count > 0 THEN
        RAISE NOTICE 'Данные сохранены во временной таблице temp_archive';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Ошибка при архивации: %', SQLERRM;
        ROLLBACK;
END;
$$;


DO $$
DECLARE
    archived INT := 0;
BEGIN
    CALL archive_old_history(365, archived);
    RAISE NOTICE 'Всего архивировано: %', archived;
END $$;
