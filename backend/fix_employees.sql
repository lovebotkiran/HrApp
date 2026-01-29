
DROP TABLE IF EXISTS employees CASCADE;

CREATE TABLE employees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) UNIQUE,
    employee_id VARCHAR(50) UNIQUE NOT NULL,
    joined_date DATE,
    department VARCHAR(100),
    designation VARCHAR(100),
    manager_id UUID REFERENCES users(id),
    employment_type VARCHAR(50),
    employment_status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_employees_department ON employees(department);
CREATE INDEX idx_employees_employment_status ON employees(employment_status);

CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON employees
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
