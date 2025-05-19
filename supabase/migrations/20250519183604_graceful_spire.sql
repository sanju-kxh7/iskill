/*
  # Enhanced Course Platform Schema

  1. New Tables
    - `courses`
      - `id` (uuid, primary key)
      - `title` (text)
      - `description` (text)
      - `price` (decimal)
      - `tutor_id` (uuid, foreign key)
      - `created_at` (timestamp)
      - `status` (text)
      - `thumbnail` (text)
      - `category` (text)
      - `level` (text)
      
    - `user_credits`
      - `id` (uuid, primary key) 
      - `user_id` (uuid, foreign key)
      - `balance` (decimal)
      - `created_at` (timestamp)
      
    - `course_purchases`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key)
      - `course_id` (uuid, foreign key)
      - `amount` (decimal)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Create courses table
CREATE TABLE IF NOT EXISTS courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  price decimal NOT NULL DEFAULT 0,
  tutor_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  status text DEFAULT 'draft',
  thumbnail text,
  category text,
  level text CHECK (level IN ('beginner', 'intermediate', 'advanced')),
  CONSTRAINT valid_price CHECK (price >= 0)
);

-- Create user credits table
CREATE TABLE IF NOT EXISTS user_credits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  balance decimal NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT positive_balance CHECK (balance >= 0)
);

-- Create course purchases table
CREATE TABLE IF NOT EXISTS course_purchases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  course_id uuid REFERENCES courses(id) ON DELETE CASCADE,
  amount decimal NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_purchases ENABLE ROW LEVEL SECURITY;

-- Policies for courses
CREATE POLICY "Public courses are viewable by everyone" 
  ON courses FOR SELECT 
  USING (status = 'published');

CREATE POLICY "Tutors can manage their own courses" 
  ON courses FOR ALL 
  USING (tutor_id = auth.uid());

-- Policies for user_credits
CREATE POLICY "Users can view their own credits"
  ON user_credits FOR SELECT
  USING (user_id = auth.uid());

-- Policies for purchases  
CREATE POLICY "Users can view their own purchases"
  ON course_purchases FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can create purchases"
  ON course_purchases FOR INSERT
  WITH CHECK (user_id = auth.uid());