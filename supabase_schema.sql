-- Supabase Database Schema for Examination Portal
-- Run these SQL commands in your Supabase SQL Editor

-- 1. Admins table
CREATE TABLE IF NOT EXISTS admins (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Students table
CREATE TABLE IF NOT EXISTS students (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    register_number VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    program VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(20),
    set_number VARCHAR(10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Question sets table
CREATE TABLE IF NOT EXISTS question_sets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    set_name VARCHAR(255) NOT NULL UNIQUE,
    admin_id UUID REFERENCES admins(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Questions table
CREATE TABLE IF NOT EXISTS questions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    question_set_id UUID REFERENCES question_sets(id) ON DELETE CASCADE,
    question_number INTEGER NOT NULL,
    question_text TEXT NOT NULL,
    option_a VARCHAR(500),
    option_b VARCHAR(500),
    option_c VARCHAR(500),
    option_d VARCHAR(500),
    correct_answer VARCHAR(500) NOT NULL,
    question_type VARCHAR(50) DEFAULT 'multiple_choice',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(question_set_id, question_number)
);

-- 5. Active test configuration
CREATE TABLE IF NOT EXISTS active_test (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    active_set_name VARCHAR(255) NOT NULL,
    question_set_id UUID REFERENCES question_sets(id),
    activated_by UUID REFERENCES admins(id),
    activated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Test submissions table
CREATE TABLE IF NOT EXISTS test_submissions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    register_number VARCHAR(100) NOT NULL,
    student_id UUID REFERENCES students(register_number),
    set_name VARCHAR(255),
    question_set_id UUID REFERENCES question_sets(id),
    total_score INTEGER DEFAULT 0,
    max_possible_score INTEGER DEFAULT 0,
    total_questions INTEGER DEFAULT 0,
    questions_attempted INTEGER DEFAULT 0,
    questions_correct INTEGER DEFAULT 0,
    time_taken_seconds INTEGER DEFAULT 0,
    tab_switch_count INTEGER DEFAULT 0,
    is_malpractice BOOLEAN DEFAULT FALSE,
    auto_submitted BOOLEAN DEFAULT FALSE,
    answers JSONB, -- Store all answers as JSON
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert sample data
-- Sample admin
INSERT INTO admins (name, password) VALUES 
('admin', 'admin123') ON CONFLICT (name) DO NOTHING;

-- Sample students
INSERT INTO students (register_number, name, password, program, email, phone, set_number) VALUES 
('student123', 'Test Student', 'student123', 'B.Tech CSE', 'test@student.com', '9876543210', '1'),
('12345', 'John Doe', 'student123', 'B.Tech IT', 'john@student.com', '9876543211', '1'),
('67890', 'Jane Smith', 'student123', 'B.Tech ECE', 'jane@student.com', '9876543212', '2')
ON CONFLICT (register_number) DO NOTHING;

-- Enable Row Level Security (RLS)
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE active_test ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_submissions ENABLE ROW LEVEL SECURITY;

-- Create policies for public access (you can make these more restrictive later)
CREATE POLICY "Allow all operations on admins" ON admins FOR ALL USING (true);
CREATE POLICY "Allow all operations on students" ON students FOR ALL USING (true);
CREATE POLICY "Allow all operations on question_sets" ON question_sets FOR ALL USING (true);
CREATE POLICY "Allow all operations on questions" ON questions FOR ALL USING (true);
CREATE POLICY "Allow all operations on active_test" ON active_test FOR ALL USING (true);
CREATE POLICY "Allow all operations on test_submissions" ON test_submissions FOR ALL USING (true);
