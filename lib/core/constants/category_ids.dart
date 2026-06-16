class CategoryIds {
  CategoryIds._();

  static const int staticWallpapers = 1;
  static const int liveWallpapers = 2;
  static const int greetingCards = 3;
  static const int frames = 4;
  static const int dpFrames = 5;

  static bool isFrameCategory(int categoryId) =>
      categoryId == frames || categoryId == dpFrames;
}
