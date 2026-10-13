# Smart Form Inputs (`CustomTextField`)

`CustomTextField` provides production-ready form inputs with zero boilerplate.

---

## Common Input Presets

### Search Input (with Clear Button)
```dart
CustomTextField.search(
  hintText: 'Search orders, customers, SKUs...',
  onChanged: (query) => runSearch(query),
)
```

### Email Input
```dart
CustomTextField.email(
  required: true,
  validator: (val) => val != null && val.contains('@') ? null : 'Enter a valid email',
)
```

### Password Input (with Visibility Eye Toggle)
```dart
CustomTextField.password(
  required: true,
  validator: (val) => (val?.length ?? 0) >= 8 ? null : 'Minimum 8 characters',
)
```

### Phone Input
```dart
CustomTextField.phone(
  label: 'Mobile Contact',
)
```

### Multiline Notes
```dart
CustomTextField.multiline(
  label: 'Customer Notes',
  hintText: 'Type meeting minutes...',
  maxLength: 500,
)
```

---

## Custom Styling & Glassmorphism

```dart
CustomTextField(
  label: 'Organization Name',
  hintText: 'Acme Corp',
  variant: TextFieldVariant.glass, // Frosted glass appearance
  prefixIcon: Icons.business_rounded,
  borderColor: Colors.cyanAccent.withOpacity(0.4),
  focusedBorderColor: Colors.cyanAccent,
)
```
