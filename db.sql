-- PostgreSQL Database
-- Add Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create Database
CREATE DATABASE "postgres";

USE "postgres";

-- Create Schema
CREATE SCHEMA "public";

USE "public";

-- Users Table
CREATE TABLE "users"(
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "email" varchar(255) NOT NULL,
    "password_hashed" varchar(255) NOT NULL,
    "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

-- Password Hashing
CREATE OR REPLACE FUNCTION "hash_password"("password" varchar(255))
    RETURNS varchar (
        255
)
    AS $$
BEGIN
    RETURN crypt($1, gen_salt('bf'));
END;
    -- Create User
    CREATE OR REPLACE FUNCTION "create_user"("email" varchar(255 ), "password" varchar(255 ) )
        RETURNS uuid AS
$$ DECLARE "user_id" uuid;

BEGIN
    INSERT INTO "users"("email", "password_hashed")
        VALUES ($1, hash_password($2))
    RETURNING
        "id" INTO "user_id";

RETURN "user_id";

END;

-- Get User
CREATE OR REPLACE FUNCTION "get_user"("email" varchar(255))
    RETURNS TABLE(
        "id" uuid,
        "email" varchar(255),
        "password_hashed" varchar(255),
        "created_at" timestamp,
        "updated_at" timestamp
    )
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        *
    FROM
        "users"
    WHERE
        "email" = $1;
END;
    -- Update User
    CREATE OR REPLACE FUNCTION "update_user"("id" uuid, "email" varchar(255 ), "password" varchar(255 ) )
        RETURNS TABLE(
            "id" uuid,
            "email" varchar(255 ),
            "password_hashed" varchar(255 ),
            "created_at" timestamp,
            "updated_at" timestamp
        ) AS
$$
BEGIN
    RETURN QUERY UPDATE "users"
    SET "email" = $2,
    "password_hashed" = hash_password($3),
"updated_at" = CURRENT_TIMESTAMP
WHERE
    "id" = $1
RETURNING
    *;

END;

-- Delete User
CREATE OR REPLACE FUNCTION "delete_user"("id" uuid)
    RETURNS TABLE(
        "id" uuid,
        "email" varchar(255),
        "password_hashed" varchar(255),
        "created_at" timestamp,
        "updated_at" timestamp
    )
    AS $$
BEGIN
    RETURN QUERY DELETE FROM "users"
    WHERE "id" = $1
    RETURNING
        *;
END;
