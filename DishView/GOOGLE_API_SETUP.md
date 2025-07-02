# Google Custom Search API Setup Guide

This guide will help you set up Google Custom Search API for the Dish View app to enable dish image search functionality.

## Prerequisites

- Google Cloud Platform account
- Google Custom Search API enabled
- Custom Search Engine configured

## Step 1: Enable Google Custom Search API

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Navigate to "APIs & Services" > "Library"
4. Search for "Custom Search API"
5. Click on "Custom Search API" and press "Enable"

## Step 2: Create API Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "API Key"
3. Copy the generated API key
4. (Optional) Restrict the API key to Custom Search API only for security

## Step 3: Create Custom Search Engine

1. Go to [Google Programmable Search Engine](https://programmablesearchengine.google.com/)
2. Click "Create a search engine"
3. Enter any website URL (e.g., `https://www.google.com`)
4. Give your search engine a name (e.g., "Dish View Image Search")
5. Click "Create"
6. Go to "Setup" > "Basic"
7. Enable "Image Search"
8. Copy the Search Engine ID (cx parameter)

## Step 4: Configure the App

### Option A: Environment Variables (Recommended for Production)

Set these environment variables in your deployment environment:

```bash
export GOOGLE_CUSTOM_SEARCH_API_KEY="your_api_key_here"
export GOOGLE_CUSTOM_SEARCH_ENGINE_ID="your_search_engine_id_here"
```

### Option B: Configuration File (Development Only)

1. Copy `Config.plist` to your project
2. Replace the placeholder values with your actual credentials:

```xml
<key>GOOGLE_CUSTOM_SEARCH_API_KEY</key>
<string>AIzaSyC...your_actual_api_key...</string>
<key>GOOGLE_CUSTOM_SEARCH_ENGINE_ID</key>
<string>012345678901234567890:abcdefghijk</string>
```

⚠️ **Important**: Never commit the actual API credentials to version control!

## Step 5: Test the Integration

1. Build and run the app
2. Take a photo of a menu or upload menu images
3. Extract dishes and confirm restaurant name
4. The app should now search for and display dish images

## API Usage and Limits

- **Free Tier**: 100 searches per day
- **Paid Tier**: $5 per 1000 searches
- **Rate Limits**: 10,000 searches per day per API key

## Troubleshooting

### Common Issues

1. **"API key not configured" error**
   - Ensure the API key is properly set in environment variables or Config.plist
   - Verify the API key is valid and not restricted

2. **"Search Engine ID not configured" error**
   - Ensure the Search Engine ID is properly set
   - Verify the Search Engine has Image Search enabled

3. **No images found**
   - Check if the search query is too specific
   - Verify the Custom Search Engine is configured for image search
   - Check API usage limits

4. **Image download failures**
   - Some image URLs may be blocked or expired
   - The app will try multiple results automatically

### Debug Information

The app includes comprehensive error handling and will display specific error messages for:
- Invalid API credentials
- Network connectivity issues
- API rate limiting
- Image download failures

## Security Best Practices

1. **Never commit API keys to version control**
2. **Use environment variables in production**
3. **Restrict API keys to specific APIs and domains**
4. **Monitor API usage regularly**
5. **Rotate API keys periodically**

## Cost Optimization

1. **Cache search results** to reduce API calls
2. **Use specific search queries** to improve result quality
3. **Monitor usage** to stay within free tier limits
4. **Consider implementing local image storage** for frequently searched dishes

## Support

For API-related issues:
- [Google Custom Search API Documentation](https://developers.google.com/custom-search/v1/overview)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Google Programmable Search Engine](https://programmablesearchengine.google.com/)

For app-related issues:
- Check the app's error messages
- Review the console logs
- Ensure all configuration steps are completed 