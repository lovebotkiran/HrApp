#!/bin/bash

# AgenticHR Backend Setup Script

echo "🚀 Setting up AgenticHR Backend..."

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.10 or higher."
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"

# Create virtual environment
echo "📦 Creating virtual environment..."
python3 -m venv venv

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "⬆️  Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "📥 Installing dependencies..."

# Install PostgreSQL adapter separately (works better)
pip install psycopg2-binary

# Install other requirements
pip install fastapi==0.104.1
pip install uvicorn[standard]==0.24.0
pip install python-multipart==0.0.6
pip install "python-jose[cryptography]==3.3.0"
pip install "passlib[bcrypt]==1.7.4"
pip install python-dotenv==1.0.0
pip install pydantic==2.5.0
pip install pydantic-settings==2.1.0
pip install sqlalchemy==2.0.23
pip install alembic==1.13.0
pip install boto3==1.29.7
pip install transformers==4.35.2
pip install torch==2.1.1
pip install sentence-transformers==2.2.2
pip install python-docx==1.1.0
pip install reportlab==4.0.7
pip install PyPDF2==3.0.1
pip install aiosmtplib==3.0.1
pip install jinja2==3.1.2
pip install celery==5.3.4
pip install redis==5.0.1
pip install httpx==0.25.2
pip install aiofiles==23.2.1
pip install python-dateutil==2.8.2
pip install pytz==2023.3

echo "✅ Dependencies installed successfully!"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "⚠️  Please update .env file with your configuration"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Update .env file with your database credentials"
echo "2. Create PostgreSQL database: createdb agentichr"
echo "3. Run database migrations: psql -U postgres -d agentichr -f ../database/schema.sql"
echo "4. Load seed data: psql -U postgres -d agentichr -f ../database/seed_data.sql"
echo "5. Start the server: source venv/bin/activate && python main.py"
echo ""
echo "Or use Docker: cd .. && docker-compose up -d"
