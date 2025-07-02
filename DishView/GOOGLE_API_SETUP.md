# Google API Setup Guide

This guide will help you set up Google APIs for the Dish View app:
- **Google Custom Search API** for dish image search functionality
- **Google Gemini API** for advanced text extraction from menu images

## Prerequisites

- Google Cloud Platform account
- Google Custom Search API enabled
- Google Gemini API enabled
- Custom Search Engine configured

## Part 1: Google Custom Search API Setup

### Step 1: Enable Google Custom Search API

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Navigate to "APIs & Services" > "Library"
4. Search for "Custom Search API"
5. Click on "Custom Search API" and press "Enable"

### Step 2: Create Custom Search API Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "API Key"
3. Copy the generated API key
4. (Optional) Restrict the API key to Custom Search API only for security

### Step 3: Create Custom Search Engine

1. Go to [Google Programmable Search Engine](https://programmablesearchengine.google.com/)
2. Click "Create a search engine"
3. Enter any website URL (e.g., `https://www.google.com`)
4. Give your search engine a name (e.g., "Dish View Image Search")
5. Click "Create"
6. Go to "Setup" > "Basic"
7. Enable "Image Search"
8. Copy the Search Engine ID (cx parameter)

## Part 2: Google Gemini API Setup

### Step 1: Enable Google Gemini API

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to "APIs & Services" > "Library"
3. Search for "Gemini API"
4. Click on "Gemini API" and press "Enable"

### Step 2: Create Gemini API Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "API Key"
3. Copy the generated API key
4. (Optional) Restrict the API key to Gemini API only for security

**Note**: You can use the same API key for both Custom Search and Gemini APIs, or create separate keys for better security control.

## Part 3: Configure the App

### Option A: Environment Variables (Recommended for Production)

Set these environment variables in your deployment environment:

```bash
# Custom Search API
export GOOGLE_CUSTOM_SEARCH_API_KEY="your_custom_search_api_key_here"
export GOOGLE_CUSTOM_SEARCH_ENGINE_ID="your_search_engine_id_here"

# Gemini API
export GOOGLE_GEMINI_API_KEY="your_gemini_api_key_here"
```

### Option B: Configuration File (Development Only)

1. Copy `Config.plist` to your project
2. Replace the placeholder values with your actual credentials:

```xml
<!-- Custom Search API -->
<key>GOOGLE_CUSTOM_SEARCH_API_KEY</key>
<string>AIzaSyC...your_custom_search_api_key...</string>
<key>GOOGLE_CUSTOM_SEARCH_ENGINE_ID</key>
<string>012345678901234567890:abcdefghijk</string>

<!-- Gemini API -->
<key>GOOGLE_GEMINI_API_KEY</key>
<string>AIzaSyC...your_gemini_api_key...</string>
```

⚠️ **Important**: Never commit the actual API credentials to version control!

## Part 4: Test the Integration

1. Build and run the app
2. Take a photo of a menu or upload menu images
3. The app will use Gemini API to extract restaurant and dish information
4. Confirm restaurant name and extracted dishes
5. The app will use Custom Search API to search for and display dish images

## API Usage and Limits

### Google Custom Search API
- **Free Tier**: 100 searches per day
- **Paid Tier**: $5 per 1000 searches
- **Rate Limits**: 10,000 searches per day per API key

### Google Gemini API
- **Free Tier**: 15 requests per minute, 1500 requests per day
- **Paid Tier**: $0.00025 per 1K characters input, $0.0005 per 1K characters output
- **Rate Limits**: Varies by model and usage tier

## Troubleshooting

### Common Issues

1. **"API key not configured" error**
   - Ensure both API keys are properly set in environment variables or Config.plist
   - Verify the API keys are valid and not restricted

2. **"Search Engine ID not configured" error**
   - Ensure the Search Engine ID is properly set
   - Verify the Custom Search Engine has Image Search enabled

3. **Gemini API errors**
   - Check if Gemini API is enabled in your Google Cloud project
   - Verify the API key has access to Gemini API
   - Check rate limits and usage quotas

4. **No images found**
   - Check if the search query is too specific
   - Verify the Custom Search Engine is configured for image search
   - Check API usage limits

5. **Text extraction failures**
   - Ensure the image quality is sufficient for OCR
   - Check if the menu text is clearly visible
   - Verify Gemini API is responding correctly

### Debug Information

The app includes comprehensive error handling and will display specific error messages for:
- Invalid API credentials
- Network connectivity issues
- API rate limiting
- Image download failures
- Text extraction failures

## Security Best Practices

1. **Never commit API keys to version control**
2. **Use environment variables in production**
3. **Restrict API keys to specific APIs and domains**
4. **Monitor API usage regularly**
5. **Rotate API keys periodically**
6. **Use separate API keys for different services when possible**

## Cost Optimization

1. **Cache search results** to reduce API calls
2. **Use specific search queries** to improve result quality
3. **Monitor usage** to stay within free tier limits
4. **Consider implementing local image storage** for frequently searched dishes
5. **Optimize image quality** before sending to Gemini API to reduce processing costs

## Support

For API-related issues:
- [Google Custom Search API Documentation](https://developers.google.com/custom-search/v1/overview)
- [Google Gemini API Documentation](https://ai.google.dev/docs)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Google Programmable Search Engine](https://programmablesearchengine.google.com/)

For app-related issues:
- Check the app's error messages
- Review the console logs
- Ensure all configuration steps are completed 