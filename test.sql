CREATE TABLE IF NOT EXISTS test_connection (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message VARCHAR(100) NOT NULL
);

INSERT INTO test_connection (message)
VALUES ('MySQL is working');

SELECT * FROM test_connection;