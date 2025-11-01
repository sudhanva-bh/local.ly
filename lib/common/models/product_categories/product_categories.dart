enum ProductCategories {
  tech, 
  clothing, 
  shoes, 
  groceries, 
  beauty, 
  home, 
  sports, 
  toys, 
  books, 
  automotive, 
  jewelry, 
  pets, 
  office, 
  health, 
  travel, other,
}

String categoryDisplayName(ProductCategories category) {
  switch (category) {
    case ProductCategories.tech:
      return "Tech";
    case ProductCategories.clothing:
      return "Clothing";
    case ProductCategories.shoes:
      return "Shoes";
    case ProductCategories.groceries:
      return "Groceries";
    case ProductCategories.beauty:
      return "Beauty";
    case ProductCategories.home:
      return "Home";
    case ProductCategories.sports:
      return "Sports";
    case ProductCategories.toys:
      return "Toys";
    case ProductCategories.books:
      return "Books";
    case ProductCategories.automotive:
      return "Automotive";
    case ProductCategories.jewelry:
      return "Jewelry";
    case ProductCategories.pets:
      return "Pets";
    case ProductCategories.office:
      return "Office";
    case ProductCategories.health:
      return "Health";
    case ProductCategories.travel:
      return "Travel";
    case ProductCategories.other:
    return "Other";
  }
}
