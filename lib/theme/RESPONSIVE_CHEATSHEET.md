# 🚀 Flutter Responsive Design - Quick Reference Cheat Sheet

## 📱 Core Responsive Widgets

### 1. Expanded - Fill Remaining Space
```dart
Row(
  children: [
    Container(width: 100),
    Expanded(child: Container()), // Takes all remaining space
    Container(width: 100),
  ],
)
```

### 2. Flexible - Proportional Space
```dart
Row(
  children: [
    Flexible(flex: 1, child: Widget1()), // 33%
    Flexible(flex: 2, child: Widget2()), // 67%
  ],
)
```

### 3. MediaQuery - Screen Info
```dart
// Screen dimensions
MediaQuery.of(context).size.width
MediaQuery.of(context).size.height

// Percentage width/height
MediaQuery.of(context).size.width * 0.8  // 80% width
MediaQuery.of(context).size.height * 0.5 // 50% height

// Safe area padding
MediaQuery.of(context).padding.top
```

### 4. SafeArea - Avoid Notch/Status Bar
```dart
Scaffold(
  body: SafeArea(
    child: YourContent(),
  ),
)
```

### 5. LayoutBuilder - Parent-Based Responsive
```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      return DesktopLayout();
    }
    return MobileLayout();
  },
)
```

### 6. FractionallySizedBox - Percentage Sizing
```dart
FractionallySizedBox(
  widthFactor: 0.8,  // 80% width
  heightFactor: 0.5, // 50% height
  child: Container(),
)
```

### 7. AspectRatio - Maintain Ratio
```dart
AspectRatio(
  aspectRatio: 16 / 9, // 16:9 ratio
  child: Image.network(url),
)
```

## 🎯 KisanBazaar Utilities

### AppResponsive - Quick Methods
```dart
// Device type check
AppResponsive.isMobile(context)
AppResponsive.isTablet(context)
AppResponsive.isDesktop(context)

// Screen dimensions
AppResponsive.screenWidth(context)
AppResponsive.screenHeight(context)

// Percentage sizing
AppResponsive.widthPercent(context, 80)  // 80% width
AppResponsive.heightPercent(context, 50) // 50% height

// Responsive values
AppResponsive.responsiveValue(
  context,
  mobile: 2,
  tablet: 3,
  desktop: 4,
)

// Responsive font size
AppResponsive.fontSize(context, 16) // Auto-scales

// Grid columns
AppResponsive.gridColumnCount(context) // 2/3/4 based on device
```

### AppSpacing - Consistent Spacing
```dart
AppSpacing.xs   // 4px
AppSpacing.sm   // 8px
AppSpacing.md   // 16px
AppSpacing.lg   // 24px
AppSpacing.xl   // 32px
AppSpacing.xxl  // 48px

// Responsive padding
AppSpacing.allPadding(context)
AppSpacing.horizontalPadding(context)
AppSpacing.verticalPadding(context)
```

### Custom Responsive Widgets
```dart
// Responsive layout
ResponsiveLayout(
  mobile: MobileWidget(),
  tablet: TabletWidget(),
  desktop: DesktopWidget(),
)

// Responsive container
ResponsiveContainer(
  widthPercent: 80,
  heightPercent: 50,
  child: YourWidget(),
)

// Centered content with max width
CenteredContent(
  maxWidth: 1200,
  child: YourContent(),
)

// Responsive grid
ResponsiveGrid(
  mobileColumns: 2,
  tabletColumns: 3,
  desktopColumns: 4,
  children: [Widget1(), Widget2()],
)
```

## 📐 Common Patterns

### Pattern 1: Responsive Grid
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: AppResponsive.gridColumnCount(context),
    crossAxisSpacing: AppSpacing.md,
    mainAxisSpacing: AppSpacing.md,
  ),
  itemBuilder: (context, index) => ProductCard(),
)
```

### Pattern 2: Row/Column Switch
```dart
Flex(
  direction: AppResponsive.isMobile(context) 
    ? Axis.vertical 
    : Axis.horizontal,
  children: [Widget1(), Widget2()],
)
```

### Pattern 3: Percentage Width Container
```dart
Container(
  width: MediaQuery.of(context).size.width * 0.8, // 80% width
  child: YourWidget(),
)
```

### Pattern 4: Safe Area + Padding
```dart
Scaffold(
  body: SafeArea(
    child: Padding(
      padding: AppSpacing.allPadding(context),
      child: YourContent(),
    ),
  ),
)
```

### Pattern 5: Responsive Font Size
```dart
Text(
  'Hello',
  style: TextStyle(
    fontSize: AppResponsive.fontSize(context, 16),
  ),
)
```

### Pattern 6: Two Column Desktop Layout
```dart
Row(
  children: [
    Expanded(
      flex: 2,
      child: MainContent(),
    ),
    Flexible(
      flex: 1,
      child: Sidebar(),
    ),
  ],
)
```

### Pattern 7: Responsive Image
```dart
AspectRatio(
  aspectRatio: 16 / 9,
  child: Image.network(url, fit: BoxFit.cover),
)
```

### Pattern 8: Conditional Widget
```dart
if (AppResponsive.isDesktop(context))
  DesktopOnlyWidget(),
```

## 🎨 Breakpoints

```dart
Mobile:  < 600px
Tablet:  600px - 900px
Desktop: > 900px
```

## ✅ Quick Checklist

- [ ] Use `SafeArea` for full-screen layouts
- [ ] Use `Expanded`/`Flexible` instead of fixed widths
- [ ] Use percentage-based sizing for containers
- [ ] Use responsive spacing from `AppSpacing`
- [ ] Test on mobile, tablet, and desktop
- [ ] Test portrait and landscape orientations
- [ ] Use `AppResponsive` utilities instead of raw `MediaQuery`
- [ ] Use responsive font sizes
- [ ] Use responsive grid columns
- [ ] Consider different layouts per device type

## 🚫 Common Mistakes

❌ Fixed widths: `Container(width: 300)`
✅ Percentage: `ResponsiveContainer(widthPercent: 80)`

❌ Hardcoded columns: `crossAxisCount: 2`
✅ Responsive: `crossAxisCount: AppResponsive.gridColumnCount(context)`

❌ Fixed padding: `padding: EdgeInsets.all(16)`
✅ Responsive: `padding: AppSpacing.allPadding(context)`

❌ No SafeArea: Content hidden by notch
✅ SafeArea: `SafeArea(child: YourContent())`

## 📚 Example Files

Check these files for complete examples:
- `lib/screens/examples/responsive_cart_example.dart` - Full responsive cart
- `lib/theme/app_responsive.dart` - All utilities
- `lib/theme/RESPONSIVE_GUIDE.md` - Detailed guide
