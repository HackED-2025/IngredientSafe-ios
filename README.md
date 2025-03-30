# Grocery Product Scanning iOS App

This iOS app helps users with dietary restrictions/preferences quickly get a health score using a camera scan form their phone. Users can quickly find out about complicated harmful ingredients. For instance, paprika is a spice that has the potential to be gluten contaminated, but those with Celiacs Diease may be completely unaware since it is not listed as a form of wheat, barley, or rye.

## Features

- **Real-time Scanning**: Uses the iPhone camera to detect grocery items on a shelf.
- **Text Recognition**: Uses OCR (Optical Character Recognition) to extract text from product packaging.
- **API Integration**: Fetches detailed product data, including ingredients and nutrition facts, from the USDA Branded Food Database.
- **Dietary Preferences**: Users can set dietary restrictions to filter and assess the safety of products based on their needs.
- **Favorites**: Users can save products to their favorites for quick access.
  
## Setup

To run this project, clone the repository and open it in Xcode.

### Dependencies

- **USDA API**: For fetching detailed product information.
- **OpenAI API**: Used for analyzing nutrition and dietary safety based on user preferences.

### Required API Keys

Ensure you have valid API keys for the following services:
- **USDA API**: Add your API key in the `Info.plist` under `USDA_API_KEY`.
- **OpenAI API**: Add your API key in the `Info.plist` under `OPENAI_API_KEY`.

## How to Use

1. **Scan a Product**: Open the app and point the camera at a grocery item. The app will automatically detect the item and extract relevant text from the packaging.
2. **View Product Information**: After scanning, a detailed view will display the product's name, rating, and bullet points about the ingredients and nutrition facts.
3. **Add to Favorites**: Save products you want to reference later to the "Favorites" list.
4. **Set Dietary Preferences**: In the preferences view, specify your dietary restrictions (e.g., vegan, gluten-free) to filter unsafe products.

## Architecture

The app uses SwiftUI for the user interface and integrates machine learning models for real-time object detection and OCR. Key components include:
- **CameraTextDetectionView**: Captures live camera feed and applies OCR to extract text.
- **FavoritesModel**: Manages the favorite products list and supports adding/removing products.
- **PreferencesModel**: Stores user preferences related to dietary restrictions.
- **API Handlers**: Fetches and parses product information from external APIs like USDA and OpenAI for nutrition analysis.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgements

- **USDA API**: For providing detailed product information.
- **OpenAI GPT**: For analyzing nutrition and dietary safety.
- **Apple's Vision Framework**: For text recognition via OCR.
