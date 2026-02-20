# KisanBazaar Theme System 🎨

This folder contains the complete theming system for the KisanBazaar application.

## 📁 Structure

```
lib/theme/
├── app_theme.dart          # Main theme configuration (light & dark)
├── app_colors.dart         # Color palette
├── app_text_styles.dart    # Typography styles
└── app_decorations.dart    # Reusable decorations
```

## 🎨 Color Palette

The theme uses an agricultural/nature-inspired green color scheme:

- **Primary**: Deep Green (#2E7D32) - Main brand color
- **Secondary**: Brown (#8D6E63) - Earthy tones
- **Accent**: Golden Yellow (#FFB300) - Harvest theme
- **Status Colors**: Success (green), Error (red), Warning (orange), Info (blue)

## 📝 How to Use

### 1. Using Colors

```dart
import 'package:kisanbazaar/theme/app_colors.dart';

Container(
  color: AppColors.primary,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.textLight),
  ),
)

// Using gradients
Container(
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
  ),
)
```

### 2. Using Text Styles

```dart
import 'package:kisanbazaar/theme/app_text_styles.dart';

Text('Product Name', style: AppTextStyles.productName),
Text('₹299', style: AppTextStyles.price),
Text('Category', style: AppTextStyles.categoryLabel),
Text('Description', style: AppTextStyles.bodyMedium),
```

### 3. Using Decorations

```dart
import 'package:kisanbazaar/theme/app_decorations.dart';

// Card decoration
Container(
  decoration: AppDecorations.cardDecoration,
  child: YourWidget(),
)

// Input field
TextField(
  decoration: AppDecorations.inputDecoration(
    labelText: 'Email',
    prefixIcon: Icons.email,
  ),
)

// Buttons
ElevatedButton(
  style: AppDecorations.primaryButtonStyle,
  onPressed: () {},
  child: Text('Submit'),
)
```

### 4. Using Theme Colors (Recommended)

Instead of hardcoding colors, use theme colors for better dark mode support:

```dart
// Get colors from theme
final primaryColor = Theme.of(context).colorScheme.primary;
final textColor = Theme.of(context).colorScheme.onSurface;

// Use theme text styles
Text(
  'Hello',
  style: Theme.of(context).textTheme.headlineMedium,
)
```

## 🌙 Dark Mode

Dark mode is already configured! To enable it:

In `main.dart`, change:
```dart
themeMode: ThemeMode.light,  // Always light
```

To:
```dart
themeMode: ThemeMode.dark,   // Always dark
// OR
themeMode: ThemeMode.system, // Follow system settings
```

## 🔧 Customization

### Changing Colors

Edit `app_colors.dart` to change the color palette:

```dart
static const Color primary = Color(0xFF2E7D32); // Change this hex code
```

### Adding New Text Styles

Add to `app_text_styles.dart`:

```dart
static const TextStyle myCustomStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: AppColors.primary,
);
```

### Adding New Decorations

Add to `app_decorations.dart`:

```dart
static BoxDecoration myCustomDecoration = BoxDecoration(
  color: AppColors.surface,
  borderRadius: radiusLarge,
  boxShadow: const [shadowMedium],
);
```

## 💡 Best Practices

1. **Always use theme colors** instead of hardcoding colors
2. **Use predefined text styles** for consistency
3. **Reuse decorations** from `app_decorations.dart`
4. **Test both light and dark themes** when making changes
5. **Use semantic color names** (e.g., `primary`, `error`) instead of color values

## 🚀 Quick Examples

### Product Card
```dart
Container(
  decoration: AppDecorations.productCardDecoration,
  padding: EdgeInsets.all(16),
  child: Column(
    children: [
      Text('Tomatoes', style: AppTextStyles.productName),
      Text('₹50/kg', style: AppTextStyles.price),
      Text('Fresh from farm', style: AppTextStyles.bodySmall),
    ],
  ),
)
```

### Status Badge
```dart
Container(
  decoration: AppDecorations.badgeDecoration(AppColors.success),
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  child: Text('In Stock', style: AppTextStyles.labelSmall),
)
```

### Gradient Button
```dart
Container(
  decoration: AppDecorations.gradientDecorationRounded,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    onPressed: () {},
    child: Text('Buy Now'),
  ),
)
```

## 📚 Resources

- [Material Design 3](https://m3.material.io/)
- [Flutter Theming Guide](https://docs.flutter.dev/cookbook/design/themes)
- [Color Tool](https://m2.material.io/resources/color/)
