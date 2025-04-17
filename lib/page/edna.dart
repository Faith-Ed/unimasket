// After adding/updating the item in the cart, close the bottom sheet
Navigator.pop(context);

Navigator.push(
context,
MaterialPageRoute(
builder: (context) => CartScreen(userId: userId),
),
);