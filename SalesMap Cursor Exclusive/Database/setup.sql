-- SalesMap Database Setup Script
-- Execute this in your Supabase SQL Editor

-- Create the markers table (used by the app)
CREATE TABLE IF NOT EXISTS markers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('sold', 'no_interest', 'not_home')),
    salesman_name TEXT NOT NULL,
    team_number INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create the sales_markers table (legacy compatibility)
CREATE TABLE IF NOT EXISTS sales_markers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('sold', 'not_interested', 'not_home')),
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    salesman_name TEXT NOT NULL,
    team_number INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for better query performance on markers table
CREATE INDEX IF NOT EXISTS idx_markers_created_at ON markers(created_at);
CREATE INDEX IF NOT EXISTS idx_markers_status ON markers(status);
CREATE INDEX IF NOT EXISTS idx_markers_team ON markers(team_number);
CREATE INDEX IF NOT EXISTS idx_markers_salesman ON markers(salesman_name);
CREATE INDEX IF NOT EXISTS idx_markers_location ON markers(latitude, longitude);

-- Add indexes for better query performance on sales_markers table
CREATE INDEX IF NOT EXISTS idx_sales_markers_timestamp ON sales_markers(timestamp);
CREATE INDEX IF NOT EXISTS idx_sales_markers_status ON sales_markers(status);
CREATE INDEX IF NOT EXISTS idx_sales_markers_team ON sales_markers(team_number);
CREATE INDEX IF NOT EXISTS idx_sales_markers_salesman ON sales_markers(salesman_name);
CREATE INDEX IF NOT EXISTS idx_sales_markers_location ON sales_markers(latitude, longitude);

-- Enable Row Level Security
ALTER TABLE markers ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_markers ENABLE ROW LEVEL SECURITY;

-- Create permissive policies for field sales use case
-- Allow both authenticated and anonymous (anon) users to access data
-- This is suitable for field sales where users might not have accounts

-- Markers table policies
CREATE POLICY "Allow read access for all users" ON markers
    FOR SELECT 
    TO authenticated, anon
    USING (true);

CREATE POLICY "Allow insert for all users" ON markers
    FOR INSERT 
    TO authenticated, anon
    WITH CHECK (true);

CREATE POLICY "Allow update for all users" ON markers
    FOR UPDATE 
    TO authenticated, anon
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow delete for all users" ON markers
    FOR DELETE 
    TO authenticated, anon
    USING (true);

-- Sales_markers table policies (for compatibility)
CREATE POLICY "Allow read access for all users" ON sales_markers
    FOR SELECT 
    TO authenticated, anon
    USING (true);

CREATE POLICY "Allow insert for all users" ON sales_markers
    FOR INSERT 
    TO authenticated, anon
    WITH CHECK (true);

CREATE POLICY "Allow update for all users" ON sales_markers
    FOR UPDATE 
    TO authenticated, anon
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow delete for all users" ON sales_markers
    FOR DELETE 
    TO authenticated, anon
    USING (true);

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers to automatically update updated_at
CREATE TRIGGER update_markers_updated_at 
    BEFORE UPDATE ON markers 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sales_markers_updated_at 
    BEFORE UPDATE ON sales_markers 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Insert some sample data into both tables for testing
INSERT INTO markers (latitude, longitude, status, salesman_name, team_number) VALUES
    (40.7128, -74.0060, 'sold', 'John Doe', 1),
    (40.7130, -74.0058, 'no_interest', 'Jane Smith', 1),
    (40.7125, -74.0062, 'not_home', 'Mike Johnson', 2),
    (40.7132, -74.0055, 'sold', 'Sarah Wilson', 2),
    (40.7120, -74.0065, 'sold', 'Tom Brown', 3)
ON CONFLICT (id) DO NOTHING;

INSERT INTO sales_markers (latitude, longitude, status, timestamp, salesman_name, team_number) VALUES
    (40.7128, -74.0060, 'sold', NOW() - INTERVAL '1 hour', 'John Doe', 1),
    (40.7130, -74.0058, 'not_interested', NOW() - INTERVAL '2 hours', 'Jane Smith', 1),
    (40.7125, -74.0062, 'not_home', NOW() - INTERVAL '3 hours', 'Mike Johnson', 2),
    (40.7132, -74.0055, 'sold', NOW() - INTERVAL '1 day', 'Sarah Wilson', 2),
    (40.7120, -74.0065, 'sold', NOW() - INTERVAL '2 days', 'Tom Brown', 3)
ON CONFLICT (id) DO NOTHING;

-- Verify the setup
SELECT 'Setup complete! Markers table:' as message;
SELECT COUNT(*) as marker_count FROM markers;
SELECT 'Sample markers data:' as message;
SELECT * FROM markers ORDER BY created_at DESC LIMIT 3; 