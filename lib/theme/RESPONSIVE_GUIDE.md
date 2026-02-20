# 📱 Responsive Design Guide for KisanBazaar

Complete guide for building responsive Flutter apps that work on all screen sizes.

## 📐 Screen Breakpoints

```dart
Mobile:  < 600px
Tablet:  600px - 900px
Desktop: > 900px
```

## 🛠️ Core Flutter Responsive Widgets

### 1. **Expanded** - Fill Available Space

```dart
Row(
  children: [
    Container(width: 100, color: Colors.red),
    Expanded(
      child: Container(color: Colors.blue), // Takes remaining space
    ),
    Container(width: 100, color: Colors.green),
  ],
)
```

**Use Case**: When you want a widget to fill remaining space in Row/Column

### 2. **Flexible** - Proportional Space Distribution

```dart
Row(
  children: [
    Flexible(
      flex: 1, // Takes 1/3 of space
      child: Container(color: Colors.red),
    ),
    Flexible(
      flex: 2, // Takes 2/3 of space
      child: Container(color: Colors.blue),
    ),
  ],
)
```

**Use Case**: When you want proportional sizing (like 30%-70% split)

### 3. **MediaQuery** - Get Screen Dimensions

```dart
// Get screen size
final screenWidth = MediaQuery.of(context).size.width;
final screenHeight = MediaQuery.of(context).size.height;

// Get safe area padding (notch, status bar)
final padding = MediaQuery.of(context).padding;

// Get orientation
final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

// Example: 80% width container
Container(
  width: MediaQuery.of(context).size.width * 0.8,
  child: Text('80% width'),
)
```

### 4. **SafeArea** - Avoid System UI Overlaps

```dart
Scaffold(
  body: SafeArea(
    child: Column(
      children: [
        Text('This text won\'t be hidden by notch or status bar'),
      ],
    ),
  ),
)
```

**Use Case**: Prevent content from being hidden by notch, status bar, or home indicator

### 5. **LayoutBuilder** - Responsive Based on Parent Size

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      return DesktopLayout();
    } else {
      return MobileLayout();
    }
  },
)
```

### 6. **FractionallySizedBox** - Percentage-Based Sizing

```dart
FractionallySizedBox(
  widthFactor: 0.8,  // 80% of parent width
  heightFactor: 0.5, // 50% of parent height
  child: Container(color: Colors.blue),
)
```

### 7. **AspectRatio** - Maintain Aspect Ratio

```dart
AspectRatio(
  aspectRatio: 16 / 9, // 16:9 ratio (like YouTube videos)
  child: Container(color: Colors.blue),
)
```

## 🎯 KisanBazaar Responsive Utilities

### Using AppResponsive Class

```dart
import 'package:kisanbazaar/theme/app_responsive.dart';

// Check device type
if (AppResponsive.isMobile(context)) {
  // Show mobile layout
}

// Get screen dimensions
final width = AppResponsive.screenWidth(context);
final height = AppResponsive.screenHeight(context);

// Get percentage of screen
final halfWidth = AppResponsive.widthPercent(context, 50); // 50% width
final quarterHeight = AppResponsive.heightPercent(context, 25); // 25% height

// Responsive values
final columns = AppResponsive.responsiveValue(
  context,
  mobile: 2,    // 2 columns on mobile
  tablet: 3,    // 3 columns on tablet
  desktop: 4,   // 4 columns on desktop
);

// Responsive font size
final fontSize = AppResponsive.fontSize(context, 16); // Auto-scales
```

### Using AppSpacing Class

```dart
import 'package:kisanbazaar/theme/app_responsive.dart';

// Fixed spacing
SizedBox(height: AppSpacing.md), // 16px
SizedBox(height: AppSpacing.lg), // 24px

// Responsive padding
Container(
  padding: AppSpacing.allPadding(context), // Auto-adjusts per device
  child: Text('Content'),
)
```

### Using Responsive Widgets

#### ResponsiveLayout - Different Layouts Per Device

```dart
ResponsiveLayout(
  mobile: MobileProductList(),
  tablet: TabletProductGrid(),
  desktop: DesktopProductGrid(),
)
```

#### ResponsiveContainer - Percentage-Based Container

```dart
ResponsiveContainer(
  widthPercent: 90,  // 90% of screen width
  heightPercent: 50, // 50% of screen height
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(color: Colors.white),
  child: Text('Responsive Container'),
)
```

#### ResponsiveGrid - Auto-Adjusting Grid

```dart
ResponsiveGrid(
  mobileColumns: 2,
  tabletColumns: 3,
  desktopColumns: 4,
  spacing: 16,
  children: [
    ProductCard(),
    ProductCard(),
    ProductCard(),
  ],
)
```

#### CenteredContent - Max Width Container

```dart
CenteredContent(
  maxWidth: 1200,
  child: YourContent(),
)
```

## 📋 Common Responsive Patterns

### Pattern 1: Responsive Product Grid

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: AppResponsive.gridColumnCount(context),
    crossAxisSpacing: AppSpacing.md,
    mainAxisSpacing: AppSpacing.md,
    childAspectRatio: 0.75,
  ),
  itemBuilder: (context, index) => ProductCard(),
)
```

### Pattern 2: Responsive Row/Column Switch

```dart
// Row on tablet/desktop, Column on mobile
Flex(
  direction: AppResponsive.isMobile(context) 
    ? Axis.vertical 
    : Axis.horizontal,
  children: [
    Flexible(child: Widget1()),
    Flexible(child: Widget2()),
  ],
)
```

### Pattern 3: Responsive Card Layout

```dart
Card(
  child: Padding(
    padding: AppSpacing.allPadding(context),
    child: Column(
      children: [
        // Image takes 40% of screen height on mobile
        ResponsiveSizedBox(
          heightPercent: AppResponsive.isMobile(context) ? 40 : 30,
          child: Image.network(imageUrl),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          'Product Name',
          style: TextStyle(
            fontSize: AppResponsive.fontSize(context, 18),
          ),
        ),
      ],
    ),
  ),
)
```

### Pattern 4: Safe Area with Responsive Padding

```dart
Scaffold(
  body: SafeArea(
    child: Padding(
      padding: AppSpacing.horizontalPadding(context),
      child: YourContent(),
    ),
  ),
)
```

### Pattern 5: Responsive App Bar

```dart
AppBar(
  title: Text('KisanBazaar'),
  actions: [
    if (AppResponsive.isDesktop(context)) ...[
      TextButton(onPressed: () {}, child: Text('Home')),
      TextButton(onPressed: () {}, child: Text('Products')),
      TextButton(onPressed: () {}, child: Text('Cart')),
    ] else ...[
      IconButton(icon: Icon(Icons.menu), onPressed: () {}),
    ],
  ],
)
```

### Pattern 6: Responsive Bottom Sheet vs Dialog

```dart
void showResponsiveModal(BuildContext context) {
  if (AppResponsive.isMobile(context)) {
    // Show bottom sheet on mobile
    showModalBottomSheet(
      context: context,
      builder: (context) => ModalContent(),
    );
  } else {
    // Show dialog on tablet/desktop
    showDialog(
      context: context,
      builder: (context) => Dialog(child: ModalContent()),
    );
  }
}
```

## 🎨 Real-World Examples

### Example 1: Responsive Product Card

```dart
class ProductCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      widthPercent: AppResponsive.isMobile(context) ? 100 : 48,
      decoration: AppDecorations.productCardDecoration,
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with aspect ratio
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(productImage, fit: BoxFit.cover),
          ),
          SizedBox(height: AppSpacing.sm),
          
          // Product name
          Text(
            productName,
            style: AppTextStyles.productName.copyWith(
              fontSize: AppResponsive.fontSize(context, 16),
            ),
          ),
          
          // Spacer to push price to bottom
          Spacer(),
          
          // Price
          Text(
            '₹$price',
            style: AppTextStyles.price,
          ),
        ],
      ),
    );
  }
}
```

### Example 2: Responsive Dashboard

```dart
class Dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _buildMobileLayout(),
          tablet: _buildTabletLayout(),
          desktop: _buildDesktopLayout(),
        ),
      ),
    );
  }
  
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          StatsCard(),
          ProductList(),
          OrderList(),
        ],
      ),
    );
  }
  
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(flex: 2, child: ProductList()),
        Expanded(flex: 1, child: OrderList()),
      ],
    );
  }
}
```

### Example 3: Responsive Form

```dart
class ResponsiveForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.allPadding(context),
      child: CenteredContent(
        maxWidth: 600,
        child: Column(
          children: [
            // Full width on mobile, 80% on tablet/desktop
            ResponsiveContainer(
              widthPercent: AppResponsive.isMobile(context) ? 100 : 80,
              child: TextField(
                decoration: AppDecorations.inputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icons.email,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            
            // Responsive button
            SizedBox(
              width: AppResponsive.widthPercent(context, 100),
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                child: Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## ✅ Best Practices

1. **Always use SafeArea** for full-screen layouts
2. **Use MediaQuery sparingly** - prefer AppResponsive utilities
3. **Test on multiple screen sizes** - use device preview
4. **Use Expanded/Flexible** instead of fixed widths when possible
5. **Prefer percentage-based sizing** over fixed pixel values
6. **Use responsive spacing** from AppSpacing
7. **Test both portrait and landscape** orientations
8. **Consider tablet layouts** - don't just think mobile vs desktop

## 🚫 Common Mistakes to Avoid

❌ **Don't use fixed pixel widths**
```dart
Container(width: 300) // Bad - doesn't scale
```

✅ **Use percentage or responsive values**
```dart
ResponsiveContainer(widthPercent: 80) // Good
```

❌ **Don't hardcode column counts**
```dart
GridView.count(crossAxisCount: 2) // Bad
```

✅ **Use responsive column counts**
```dart
GridView.count(
  crossAxisCount: AppResponsive.gridColumnCount(context), // Good
)
```

## 🔧 Testing Responsive Layouts

### In VS Code / Android Studio:
1. Use **Device Preview** extension
2. Test on multiple emulators
3. Use **Flutter Inspector** to check sizes

### Programmatically:
```dart
// Force different screen sizes for testing
MediaQuery(
  data: MediaQueryData(size: Size(400, 800)), // Mobile
  child: YourWidget(),
)
```

## 📚 Additional Resources

- [Flutter Responsive Design](https://docs.flutter.dev/development/ui/layout/responsive)
- [MediaQuery Documentation](https://api.flutter.dev/flutter/widgets/MediaQuery-class.html)
- [LayoutBuilder Documentation](https://api.flutter.dev/flutter/widgets/LayoutBuilder-class.html)
