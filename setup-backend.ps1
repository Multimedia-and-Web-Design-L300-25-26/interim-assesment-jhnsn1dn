# ============================================
# Full-Stack Crypto App - Backend Setup Script
# For Windows PowerShell
# ============================================

Write-Host "🚀 Setting up Full-Stack Crypto Backend..." -ForegroundColor Green

# Create directories
Write-Host "📁 Creating directories..." -ForegroundColor Cyan
$dirs = @('models', 'routes', 'controllers', 'middleware', 'config')
foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# ============================================
# 1. CREATE .env FILE
# ============================================
Write-Host "📝 Creating .env file..." -ForegroundColor Cyan
$envContent = @'
MONGODB_URI=mongodb+srv://johnsonkuzagbe:<TheKey069>@johnsoncluster.ha5wboj.mongodb.net/?appName=JohnsonCluster
JWT_SECRET=your_super_secret_jwt_key_change_this_12345
PORT=5000
NODE_ENV=development
FRONTEND_URL=https://jhnsn1dn-crypto-app.netlify.app
'@
Set-Content -Path ".env" -Value $envContent

# ============================================
# 2. CREATE .gitignore FILE
# ============================================
Write-Host "📝 Creating .gitignore file..." -ForegroundColor Cyan
$gitignoreContent = @'
node_modules/
.env
.env.local
.DS_Store
*.log
'@
Set-Content -Path ".gitignore" -Value $gitignoreContent

# ============================================
# 3. CREATE config/db.js
# ============================================
Write-Host "📝 Creating config/db.js..." -ForegroundColor Cyan
$dbContent = @'
const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI);
    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
    return conn;
  } catch (error) {
    console.error(`❌ Error: ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;
'@
Set-Content -Path "config/db.js" -Value $dbContent

# ============================================
# 4. CREATE models/User.js
# ============================================
Write-Host "📝 Creating models/User.js..." -ForegroundColor Cyan
$userModelContent = @'
const mongoose = require('mongoose');
const bcryptjs = require('bcryptjs');

const UserSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Please provide a name'],
      trim: true,
      maxlength: [50, 'Name cannot be more than 50 characters']
    },
    email: {
      type: String,
      required: [true, 'Please provide an email'],
      unique: true,
      match: [
        /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
        'Please provide a valid email'
      ]
    },
    password: {
      type: String,
      required: [true, 'Please provide a password'],
      minlength: 6,
      select: false
    }
  },
  { timestamps: true }
);

// Hash password before saving
UserSchema.pre('save', async function (next) {
  if (!this.isModified('password')) {
    return next();
  }

  try {
    const salt = await bcryptjs.genSalt(10);
    this.password = await bcryptjs.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Method to compare passwords
UserSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcryptjs.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', UserSchema);
'@
Set-Content -Path "models/User.js" -Value $userModelContent

# ============================================
# 5. CREATE models/Cryptocurrency.js
# ============================================
Write-Host "📝 Creating models/Cryptocurrency.js..." -ForegroundColor Cyan
$cryptoModelContent = @'
const mongoose = require('mongoose');

const CryptoSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Please provide cryptocurrency name'],
      unique: true,
      trim: true
    },
    symbol: {
      type: String,
      required: [true, 'Please provide cryptocurrency symbol'],
      unique: true,
      uppercase: true,
      maxlength: 10
    },
    price: {
      type: Number,
      required: [true, 'Please provide price'],
      default: 0
    },
    change24h: {
      type: Number,
      required: [true, 'Please provide 24h change percentage'],
      default: 0
    },
    image: {
      type: String,
      required: [true, 'Please provide image URL']
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: false
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Cryptocurrency', CryptoSchema);
'@
Set-Content -Path "models/Cryptocurrency.js" -Value $cryptoModelContent

# ============================================
# 6. CREATE middleware/auth.js
# ============================================
Write-Host "📝 Creating middleware/auth.js..." -ForegroundColor Cyan
$authMiddlewareContent = @'
const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
  try {
    // Get token from cookies or Authorization header
    let token = req.cookies.token || req.headers.authorization?.split(' ')[1];

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized - No token provided'
      });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.id;
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({
      success: false,
      message: 'Not authorized - Invalid token'
    });
  }
};

module.exports = authMiddleware;
'@
Set-Content -Path "middleware/auth.js" -Value $authMiddlewareContent

# ============================================
# 7. CREATE controllers/authController.js
# ============================================
Write-Host "📝 Creating controllers/authController.js..." -ForegroundColor Cyan
$authControllerContent = @'
const User = require('../models/User');
const jwt = require('jsonwebtoken');

// Generate JWT Token
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: '7d'
  });
};

// @route   POST /api/auth/register
// @desc    Register a new user
// @access  Public
exports.register = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    // Validation
    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide name, email, and password'
      });
    }

    // Check if user already exists
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with that email'
      });
    }

    // Create user
    user = await User.create({
      name,
      email,
      password
    });

    // Generate token
    const token = generateToken(user._id);

    // Set HTTP-only cookie
    res.cookie('token', token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 7 * 24 * 60 * 60 * 1000
    });

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      user: {
        id: user._id,
        name: user.name,
        email: user.email
      },
      token
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @route   POST /api/auth/login
// @desc    Login user
// @access  Public
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password'
      });
    }

    // Check user exists and get password
    const user = await User.findOne({ email }).select('+password');

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check password
    const isMatch = await user.matchPassword(password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Generate token
    const token = generateToken(user._id);

    // Set HTTP-only cookie
    res.cookie('token', token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 7 * 24 * 60 * 60 * 1000
    });

    res.status(200).json({
      success: true,
      message: 'Logged in successfully',
      user: {
        id: user._id,
        name: user.name,
        email: user.email
      },
      token
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @route   POST /api/auth/logout
// @desc    Logout user
// @access  Private
exports.logout = (req, res) => {
  res.clearCookie('token');
  res.status(200).json({
    success: true,
    message: 'Logged out successfully'
  });
};
'@
Set-Content -Path "controllers/authController.js" -Value $authControllerContent

# ============================================
# 8. CREATE controllers/profileController.js
# ============================================
Write-Host "📝 Creating controllers/profileController.js..." -ForegroundColor Cyan
$profileControllerContent = @'
const User = require('../models/User');

// @route   GET /api/profile
// @desc    Get current user profile
// @access  Private
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.status(200).json({
      success: true,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        createdAt: user.createdAt
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @route   PUT /api/profile
// @desc    Update user profile
// @access  Private
exports.updateProfile = async (req, res) => {
  try {
    const { name, email } = req.body;

    const user = await User.findByIdAndUpdate(
      req.userId,
      { name, email },
      { new: true, runValidators: true }
    );

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      user: {
        id: user._id,
        name: user.name,
        email: user.email
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};
'@
Set-Content -Path "controllers/profileController.js" -Value $profileControllerContent

# ============================================
# 9. CREATE controllers/cryptoController.js
# ============================================
Write-Host "📝 Creating controllers/cryptoController.js..." -ForegroundColor Cyan
$cryptoControllerContent = @'
const Cryptocurrency = require('../models/Cryptocurrency');

// @route   GET /api/crypto
// @desc    Get all cryptocurrencies
// @access  Public
exports.getAllCrypto = async (req, res) => {
  try {
    const cryptos = await Cryptocurrency.find().sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: cryptos.length,
      data: cryptos
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @route   GET /api/crypto/gainers
// @desc    Get top gainers (highest percentage increase)
// @access  Public
exports.getGainers = async (req, res) => {
  try {
    const gainers = await Cryptocurrency.find()
      .sort({ change24h: -1 })
      .limit(10);

    res.status(200).json({
      success: true,
      count: gainers.length,
      data: gainers
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @route   GET /api/crypto/new
// @desc    Get newest listings
// @access  Public
exports.getNewListings = async (req, res) => {
  try {
    const newListings = await Cryptocurrency.find()
      .sort({ createdAt: -1 })
      .limit(10);

    res.status(200).json({
      success: true,
      count: newListings.length,
      data: newListings
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @route   POST /api/crypto
// @desc    Create new cryptocurrency
// @access  Private
exports.createCrypto = async (req, res) => {
  try {
    const { name, symbol, price, change24h, image } = req.body;

    // Validation
    if (!name || !symbol || !price || !image) {
      return res.status(400).json({
        success: false,
        message: 'Please provide all required fields (name, symbol, price, image)'
      });
    }

    // Check if symbol already exists
    const existingCrypto = await Cryptocurrency.findOne({ symbol: symbol.toUpperCase() });
    if (existingCrypto) {
      return res.status(400).json({
        success: false,
        message: 'Cryptocurrency with this symbol already exists'
      });
    }

    const crypto = await Cryptocurrency.create({
      name,
      symbol: symbol.toUpperCase(),
      price: parseFloat(price),
      change24h: parseFloat(change24h) || 0,
      image,
      createdBy: req.userId
    });

    res.status(201).json({
      success: true,
      message: 'Cryptocurrency created successfully',
      data: crypto
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @route   DELETE /api/crypto/:id
// @desc    Delete cryptocurrency (optional - for admin)
// @access  Private
exports.deleteCrypto = async (req, res) => {
  try {
    const crypto = await Cryptocurrency.findById(req.params.id);

    if (!crypto) {
      return res.status(404).json({
        success: false,
        message: 'Cryptocurrency not found'
      });
    }

    await Cryptocurrency.findByIdAndDelete(req.params.id);

    res.status(200).json({
      success: true,
      message: 'Cryptocurrency deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};
'@
Set-Content -Path "controllers/cryptoController.js" -Value $cryptoControllerContent

# ============================================
# 10. CREATE routes/auth.js
# ============================================
Write-Host "📝 Creating routes/auth.js..." -ForegroundColor Cyan
$authRoutesContent = @'
const express = require('express');
const router = express.Router();
const { register, login, logout } = require('../controllers/authController');

router.post('/register', register);
router.post('/login', login);
router.post('/logout', logout);

module.exports = router;
'@
Set-Content -Path "routes/auth.js" -Value $authRoutesContent

# ============================================
# 11. CREATE routes/profile.js
# ============================================
Write-Host "📝 Creating routes/profile.js..." -ForegroundColor Cyan
$profileRoutesContent = @'
const express = require('express');
const router = express.Router();
const { getProfile, updateProfile } = require('../controllers/profileController');
const authMiddleware = require('../middleware/auth');

// All profile routes require authentication
router.get('/', authMiddleware, getProfile);
router.put('/', authMiddleware, updateProfile);

module.exports = router;
'@
Set-Content -Path "routes/profile.js" -Value $profileRoutesContent

# ============================================
# 12. CREATE routes/crypto.js
# ============================================
Write-Host "📝 Creating routes/crypto.js..." -ForegroundColor Cyan
$cryptoRoutesContent = @'
const express = require('express');
const router = express.Router();
const {
  getAllCrypto,
  getGainers,
  getNewListings,
  createCrypto,
  deleteCrypto
} = require('../controllers/cryptoController');
const authMiddleware = require('../middleware/auth');

// Public routes
router.get('/', getAllCrypto);
router.get('/gainers', getGainers);
router.get('/new', getNewListings);

// Private routes (require authentication)
router.post('/', authMiddleware, createCrypto);
router.delete('/:id', authMiddleware, deleteCrypto);

module.exports = router;
'@
Set-Content -Path "routes/crypto.js" -Value $cryptoRoutesContent

# ============================================
# 13. CREATE server.js
# ============================================
Write-Host "📝 Creating server.js..." -ForegroundColor Cyan
$serverContent = @'
const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
require('dotenv').config();

const connectDB = require('./config/db');

// Connect to database
connectDB();

const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

// CORS configuration (allow requests from your frontend)
app.use(cors({
  origin: process.env.FRONTEND_URL,
  credentials: true // Allow cookies to be sent
}));

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/profile', require('./routes/profile'));
app.use('/api/crypto', require('./routes/crypto'));

// Health check route
app.get('/api/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Backend is running'
  });
});

// Error handling for undefined routes
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📝 Environment: ${process.env.NODE_ENV}`);
});
'@
Set-Content -Path "server.js" -Value $serverContent

# ============================================
# 14. UPDATE package.json
# ============================================
Write-Host "📝 Updating package.json scripts..." -ForegroundColor Cyan
$packageJsonPath = "package.json"
if (Test-Path $packageJsonPath) {
    $packageJson = Get-Content $packageJsonPath | ConvertFrom-Json
    $packageJson.scripts.start = "node server.js"
    $packageJson.scripts.dev = "nodemon server.js"
    $packageJson | ConvertTo-Json -Depth 10 | Set-Content $packageJsonPath
}

# ============================================
# SUCCESS MESSAGE
# ============================================
Write-Host "`n✅ Setup Complete! All files created successfully!" -ForegroundColor Green
Write-Host "`n📁 Your project structure:" -ForegroundColor Cyan
Write-Host @'
interim-assesment-jhnsn1dn/
├── models/
│   ├── User.js
│   └── Cryptocurrency.js
├── routes/
│   ├── auth.js
│   ├── profile.js
│   └── crypto.js
├── controllers/
│   ├── authController.js
│   ├── profileController.js
│   └── cryptoController.js
├── middleware/
│   └── auth.js
├── config/
│   └── db.js
├── server.js
├── .env
├── .gitignore
└── package.json
'@

Write-Host "`n🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Update .env file with your actual MongoDB password"
Write-Host "2. Run: npm install"
Write-Host "3. Run: npm run dev"
Write-Host "4. Test at: http://localhost:5000/api/health"
Write-Host "`n✨ Happy coding! ✨" -ForegroundColor Yellow