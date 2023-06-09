-- ----------------------------------
-- PostgreSQL Database
-- ----------------------------------

-- ----------------------------------
-- Add Extensions
-- ----------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ----------------------------------
-- Create Database
-- ----------------------------------
-- CREATE DATABASE "postgres";
-- USE "postgres";

-- ----------------------------------
-- Create Schema
-- ----------------------------------
-- CREATE SCHEMA "public";
-- USE "public";

-- ----------------------------------
-- Create Tables
-- ----------------------------------

-- Users Table
CREATE TABLE "users"(
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "email" varchar(255) NOT NULL,
    "password_hashed" varchar(255) NOT NULL,
    "first_name" varchar(255) NOT NULL,
    "last_name" varchar(255) NOT NULL,
    "phone_number" varchar(255) NULL,
    "role" varchar(255) NOT NULL DEFAULT 'user',
    "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	"created_by" varchar DEFAULT current_user,
    "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_by" varchar DEFAULT current_user,
    PRIMARY KEY ("id"),
    UNIQUE ("email"),
    CHECK ("role" IN ('admin', 'viewer', 'user', 'guest'))
    -- CHECK ("phone_number" ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'),
    -- CHECK ("email" ~ '^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'),
    -- CHECK ("first_name" ~ '^[a-zA-Z]+$'),
    -- CHECK ("last_name" ~ '^[a-zA-Z]+$')
);

-- -- Procedure trigger_set_updated_by()
-- CREATE OR REPLACE FUNCTION trigger_set_updated_by()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     NEW.updated_by = current_setting('jwt.claims.user_id', true)::uuid;
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- -- Trigger Updated By
-- CREATE TRIGGER "updated_by" BEFORE UPDATE ON "users" FOR EACH ROW EXECUTE PROCEDURE trigger_set_updated_by();



-- Sessions Table
CREATE TABLE "sessions"(
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "user_id" uuid NOT NULL,
    "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("user_id") REFERENCES "users" ("id")
);

-- Roles Table
CREATE TABLE "roles"(
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "name" varchar(255) NOT NULL,
    "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

-- Items Table
CREATE TABLE "items"(
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "user_id" uuid NOT NULL,
    "name" varchar(255) NOT NULL,
    "description" varchar(255) NOT NULL,
    "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("user_id") REFERENCES "users" ("id")
);

-- ----------------------------------
-- Create Functions
-- ----------------------------------

-- Password Hashing
CREATE OR REPLACE FUNCTION hash_password(password varchar)
RETURNS varchar AS $$
BEGIN
    RETURN crypt($1, gen_salt('bf'));
END;
$$ LANGUAGE plpgsql;

-- Create User
CREATE OR REPLACE FUNCTION create_user(email varchar, password varchar)
RETURNS uuid AS $$
DECLARE user_id uuid;
BEGIN
	INSERT INTO users ("email", "password_hashed") VALUES ($1, hash_password($2))
	RETURNING "id"
	INTO user_id;

    RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- Get User
CREATE OR REPLACE FUNCTION get_user(user_email varchar)
RETURNS TABLE (LIKE users) AS $$
BEGIN
    RETURN QUERY
		SELECT *
		FROM users
		WHERE email = user_email;
END;
$$ LANGUAGE plpgsql;

-- Update User
CREATE OR REPLACE FUNCTION update_user(user_id uuid, user_email varchar, user_password varchar)
RETURNS TABLE (LIKE users) AS $$
BEGIN
    RETURN QUERY
		UPDATE "users"
		SET "email" = user_email,
			"password_hashed" = hash_password(user_password),
			"updated_at" = CURRENT_TIMESTAMP
		WHERE "id" = user_id
		RETURNING *;
END;
$$ LANGUAGE plpgsql;

-- Delete User
CREATE OR REPLACE FUNCTION delete_user(user_id uuid)
RETURNS TABLE (LIKE users) AS $$
BEGIN
    RETURN QUERY DELETE FROM users WHERE id = user_id RETURNING *;
END;
$$ LANGUAGE plpgsql;

-- -- ----------------------------------
-- -- Test Functions
-- -- ----------------------------------

-- -- Create Test User
-- SELECT create_user('test_user@test.com', 'test_password');

-- -- Get Test User
-- SELECT * FROM get_user('test_user@test.com');

-- -- Update Test User
-- SELECT * FROM update_user(
--     (SELECT id FROM get_user('test_user@test.com')),
--     'john.doe@test.com',
--     'password'
-- );

-- -- Check
-- SELECT * FROM get_user('john.doe@test.com');

-- -- Delete Test User
-- SELECT * FROM delete_user(
--     (SELECT id FROM get_user('john.doe@test.com'))
-- );

-- -- Check
-- SELECT * FROM users;

-- ----------------------------------
-- Create Roles
-- ----------------------------------

-- Create Admin Role
INSERT INTO roles ("name") VALUES ('admin');

-- Create User Role
INSERT INTO roles ("name") VALUES ('user');

-- Create Viewer Role
INSERT INTO roles ("name") VALUES ('viewer');

-- Create Guest Role
INSERT INTO roles ("name") VALUES ('guest');

-- ----------------------------------
-- Create Users
-- ----------------------------------

-- Create User
SELECT create_user('jimmy.briggs@jimbrig.com', 'password', 'Jimmy', 'Briggs', '555-555-5555', 'admin');


