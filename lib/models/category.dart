import 'package:flutter/material.dart';

enum Categories {
  vegetables,
  fruit,
  meat,
  dairy,
  carbs,
  sweets,
  spices,
  convenience,
  hygiene,
  other,
}

class Category {
  const Category(
    this.categoryName,
    this.categoryColor,
  );

  final String categoryName;
  final Color categoryColor;
}
