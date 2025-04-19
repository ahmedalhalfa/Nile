# Nile API

This is a Ruby on Rails API application for managing books and authors, featuring JWT-based authentication and Swagger documentation.

## Features

*   **Book Management:** CRUD operations for books (title, author).
*   **Author Management:** Authors associated with books (first name, last name, age).
*   **Authentication:** User registration, login, password change, and password reset functionality using JWT.
*   **API Documentation:** Interactive API documentation using Swagger (Rswag).
*   **Background Jobs:** Example background job (`UpdateSkuJob`) using SolidQueue.
*   **Testing:** Comprehensive test suite using RSpec, FactoryBot, and Shoulda Matchers.

## Setup

### Requirements

*   **Ruby:** `ruby-3.4.2` (See `.ruby-version`)
*   **Bundler:** Ensure you have Bundler installed (`gem install bundler`)
*   **SQLite3:** Development/Test database

### Installation

1.  **Clone the repository:**
    ```bash
    git clone <repository_url>
    cd nile
    ```
2.  **Install dependencies:**
    ```bash
    bundle install
    ```
3.  **Setup the database:**
    ```bash
    rails db:migrate
    ```
    *Note: This uses SQLite3 by default for development and test environments.*

## Running the Application

1.  **Start the Rails server:**
    ```bash
    rails s
    ```
2.  The API will be available at `http://localhost:3000`.

## Running Tests

Execute the test suite using RSpec:

```bash
bundle exec rspec
```

## API Documentation

This project uses `rswag` to generate Swagger/OpenAPI documentation.

1.  **Generate the `swagger.yaml` file:**
    ```bash
    rails rswag:specs:swaggerize
    ```
2.  **Start the Rails server** (if not already running):
    ```bash
    rails s
    ```
3.  **Access the documentation:** Open your browser and navigate to `http://localhost:3000/api-docs`.

## API Endpoints (v1)

All endpoints are prefixed with `/api/v1`.

### Authentication (`/auth`)

*   `POST /register`: Register a new user.
*   `POST /login`: Log in and receive a JWT.
*   `POST /forgot_password`: Request a password reset token (email sending not implemented).
*   `POST /reset_password`: Reset password using a token.
*   `PUT /change_password`: Change password (requires authentication).

### Books (`/books`)

*Requires Authentication (Bearer Token)*

*   `GET /`: List books (supports `limit` and `offset` parameters).
*   `POST /`: Create a new book.
*   `GET /{id}`: Retrieve a specific book.
*   `PUT /{id}`: Update a specific book.
*   `DELETE /{id}`: Delete a specific book.

## Key Dependencies

*   `rails`: Web framework
*   `puma`: Web server
*   `sqlite3`: Database
*   `jwt`: JSON Web Token implementation
*   `bcrypt`: Secure password hashing
*   `rspec-rails`, `factory_bot_rails`, `shoulda-matchers`: Testing
*   `rswag`: API documentation
*   `solid_queue`: Background job processing
