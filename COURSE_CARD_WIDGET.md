# CourseCard Widget - Reusable Component

## ✅ Complete Implementation

A versatile, production-ready course card widget supporting multiple course types, enrollment states, and interactive features.

---

## 📋 **Parameters**

### Required Parameters:
```dart
String title                  // Course name (e.g., "Calculus 101")
String facultyName            // Instructor name (e.g., "Kishan Sharma")
String examType               // Category: school|senior|govt|cuet|jee|neet
double rating                 // Course rating (0-5)
double price                  // Course price in ₹
VoidCallback onTap           // Card tap callback
VoidCallback onEnroll        // Enroll button callback
```

### Optional Parameters:
```dart
double? originalPrice        // Original price for discounts (shows strikethrough)
bool isFree = false         // Shows "FREE" label in green
bool isEnrolled = false     // Shows "Continue →" button instead of "Enroll Now"
bool isComingSoon = false   // Shows black overlay + "Coming Soon" badge
bool isBestseller = false   // Shows "BESTSELLER" badge on thumbnail
```

---

## 🎨 **Visual Structure**

### **Layout: Two-Column Row**

```
┌─────────────────────────────────────────────────┐
│ [110px Gradient] │ [Expanded Course Info]       │
│  Thumbnail      │                               │
│  ────────────── │  Category Badge + Price      │
│  📚 SCHOOL      │  Course Title (2 lines max)   │
│                 │  👤 Faculty Name              │
│ [BESTSELLER]    │  ⭐ 4.8 (1.2K reviews)        │
│                 │                               │
│                 │  [Enroll Now Button]          │
└─────────────────────────────────────────────────┘
```

---

## 🎯 **Left Section - Thumbnail (110px)**

### **Gradient by Exam Type:**
```
school:  Navy (#0D2240 → #1a3a6b)
senior:  Purple (#7C3AED → #9F67FF)
govt:    Green (#16A34A → #22C55E)
cuet:    Purple (#7C3AED → #4C1D95)
jee/neet: Grey (#6B7280 → #374151)
```

### **Content:**
- **Emoji** (34px): Represents exam type
  - school: 📚, senior: 🎓, govt: 🏛️, cuet: 🎯, jee: 🔬, neet: 💊
- **Badge** (white pill, rgba 0.15):
  - Shows exam category label
  - ExtraBold 9px, letter-spaced

### **Conditional Elements:**
- **Bestseller Badge** (top-left):
  - Yellow background (`#F5A623`)
  - Navy text, ExtraBold 8px
  - Shows only if `isBestseller: true`

- **Coming Soon Overlay** (full container):
  - Black 50% opacity
  - White border pill with navy text
  - "🚀 Coming Soon"
  - Shows only if `isComingSoon: true`

---

## 📖 **Right Section - Course Info (Expanded)**

### **Exam Badge Row:**
```
Colored badge (10px | 15px) | [Spacer] | Price
```
- Badge colors match gradient
- Price shows:
  - "FREE" (green) if `isFree: true`
  - "₹{price}" (navy, bold) otherwise

### **Course Title:**
- Navy, ExtraBold 14px
- Max 2 lines with ellipsis
- Padding: 6px below badge

### **Faculty Row:**
```
👤 {facultyName}
```
- Person icon (14px, grey)
- Faculty name (grey, 11px)
- Padding: 4px below title, 6px below

### **Rating Row:**
```
⭐ 4.8 {rating} | (1.2K reviews) | [Spacer] | ₹{originalPrice} ⏭️
```
- Star icon (14px, yellow)
- Rating (yellow, bold 12px)
- Review count (grey, 11px)
- Original price (if provided):
  - Grey, 11px
  - Strikethrough text decoration
- Padding: 10px below

### **Action Button (34px height):**

Three states based on enrollment status:

#### **State 1: Coming Soon**
```
OutlinedButton 'Notify Me 🔔'
- Grey border & text
- onPressed: Show SnackBar
  "You will be notified when this course launches!"
```

#### **State 2: Enrolled**
```
OutlinedButton 'Continue →'
- Navy border & text
- onPressed: onTap callback
```

#### **State 3: Not Enrolled (Default)**
```
ElevatedButton 'Enroll Now'
- Navy background, white text
- Rounded 50px (pill shape)
- onPressed: onEnroll callback
```

---

## 🔧 **Private Helper Methods**

### `_getGradientByExamType() → LinearGradient`
Returns gradient based on examType parameter

### `_getExamBadgeColor() → Color`
Returns color for exam category badge

### `_getExamLabel() → String`
Returns uppercase label: SCHOOL, SENIOR, GOVT, CUET, JEE, NEET

### `_getEmoji() → String`
Returns emoji based on exam type

### `_buildActionButton(BuildContext) → Widget`
Builds appropriate button based on course state

---

## 📱 **Usage Examples**

### **Basic Course Card:**
```dart
CourseCard(
  title: 'Calculus 101',
  facultyName: 'Kishan Sharma',
  examType: 'school',
  rating: 4.8,
  price: 2999,
  onTap: () => print('View course'),
  onEnroll: () => print('Enroll now'),
)
```

### **Free Course (Already Enrolled):**
```dart
CourseCard(
  title: 'Introduction to Physics',
  facultyName: 'Dr. Aakash',
  examType: 'senior',
  rating: 4.9,
  price: 0,
  isFree: true,
  isEnrolled: true,
  onTap: () => context.go('/courses/123'),
  onEnroll: () {},
)
```

### **Discounted Bestseller:**
```dart
CourseCard(
  title: 'CUET 2026 Comprehensive',
  facultyName: 'Expert Faculty',
  examType: 'cuet',
  rating: 4.7,
  price: 3999,
  originalPrice: 5999,
  isBestseller: true,
  onTap: () => viewCourse(),
  onEnroll: () => enrollCourse(),
)
```

### **Coming Soon:**
```dart
CourseCard(
  title: 'Advanced JEE Physics',
  facultyName: 'Dr. Vikas',
  examType: 'jee',
  rating: 4.6,
  price: 4999,
  isComingSoon: true,
  onTap: () {},
  onEnroll: () {},
)
```

---

## 🎨 **Design Specifications**

### **Colors:**
- Navy Primary: `#0D2240`
- Purple: `#7C3AED`, `#9F67FF`, `#4C1D95`
- Green: `#16A34A`, `#22C55E`
- Yellow/Orange: `#F5A623`
- Grey: `#888888`, `#E5E7EB`, `#6B7280`, `#374151`
- White: `#FFFFFF`

### **Typography:**
- Title: ExtraBold 14px
- Badge: ExtraBold 9-10px, letter-spaced
- Rating: Bold 12px
- Price: Bold 15px
- Faculty/Details: Regular 11px

### **Spacing:**
- Card margin bottom: 14px
- Card padding: All around
- Border radius: 18px
- Shadow elevation: 8
- Button height: 34px
- Thumbnail width: 110px

### **Borders:**
- Light grey: `#E5E7EB`
- Width: 1px
- Radius: 18px (parent), 50px (buttons)

---

## ✨ **Features**

✅ **Responsive Design**
- Works on all screen sizes
- Flexible right section
- Fixed 110px thumbnail

✅ **Multiple States**
- Enrolled, Not Enrolled, Coming Soon
- Bestseller badge
- Free/Discounted pricing

✅ **Interactive**
- Ripple effect on card tap
- Multiple button callbacks
- SnackBar notifications

✅ **Accessible**
- High contrast colors
- Clear typography hierarchy
- Large touch targets (34px buttons)

✅ **Performant**
- StatelessWidget
- No unnecessary rebuilds
- Efficient gradients

---

## 🚀 **Integration**

### **Import:**
```dart
import 'package:aakash_academics/presentation/widgets/course_card.dart';
```

### **In Lists:**
```dart
ListView.builder(
  itemCount: courses.length,
  itemBuilder: (context, index) {
    final course = courses[index];
    return CourseCard(
      title: course.title,
      facultyName: course.faculty,
      examType: course.category,
      rating: course.rating,
      price: course.price,
      originalPrice: course.originalPrice,
      isFree: course.isFree,
      isEnrolled: course.isEnrolled,
      isComingSoon: course.isComingSoon,
      isBestseller: course.isBestseller,
      onTap: () => context.go('/courses/detail/${course.id}'),
      onEnroll: () => enrollCourse(course.id),
    );
  },
)
```

---

## 🔗 **Used In:**
- Home Screen - Featured Courses Horizontal Scroll
- Courses Screen - Course Listing
- Category Detail Screen - Filtered Courses
- Search Results Screen - Search Results

---

## 📝 **Notes**

- The widget is fully reusable and customizable
- All parameters are documented and self-explanatory
- Gradient selection is automatic based on examType
- Button states are determined by boolean flags
- Context is captured via Builder for SnackBar support

---

**Status**: ✅ Complete and Production Ready
**File**: `lib/presentation/widgets/course_card.dart`
**Lines**: 500+
**Last Updated**: April 20, 2026
