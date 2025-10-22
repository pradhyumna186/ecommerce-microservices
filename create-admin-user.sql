-- Create an admin user for testing authorization
-- This script should be run after the user service is running and the database is initialized

-- Insert admin user (password is "admin123" encoded with BCrypt)
INSERT INTO users (first_name, last_name, email, password, phone_number, role, is_active, created_at, updated_at)
VALUES (
    'Admin',
    'User',
    'admin@example.com',
    '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', -- password: admin123
    '+15550000000',
    'ADMIN',
    true,
    NOW(),
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- Verify the admin user was created
SELECT id, first_name, last_name, email, role, is_active FROM users WHERE email = 'admin@example.com';
