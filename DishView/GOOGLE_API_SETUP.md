# Google Gemini API Setup Guide

This guide will help you set up the Google Gemini API for the Dish View app, which is now used for both text extraction and image generation.

## Prerequisites

- Google Cloud Platform account
- Google Gemini API enabled

## Step 1: Enable Google Gemini API

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to "APIs & Services" > "Library"
3. Search for "Gemini API"
4. Click on "Gemini API" and press "Enable"

## Step 2: Create Gemini API Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "API Key"
3. Copy the generated API key
4. (Optional) Restrict the API key to Gemini API only for security

## Step 3: Configure the App

### Option A: Environment Variables (Recommended for Production)

Set this environment variable in your deployment environment:

```bash
# Gemini API
export GOOGLE_GEMINI_API_KEY="your_gemini_api_key_here"
```

### Option B: Configuration File (Development Only)

1. Copy `Config.plist` to your project
2. Replace the placeholder value with your actual Gemini API credential:

```xml
<key>GEMINI_API_KEY</key>
<string>AIzaSyC...your_gemini_api_key...</string>
```

⚠️ **Important**: Never commit the actual API credentials to version control!

## Step 4: Test the Integration

1. Build and run the app
2. Take a photo of a menu or upload menu images
3. The app will use Gemini API to extract restaurant and dish information
4. Confirm restaurant name and extracted dishes
5. The app will use Gemini API to generate and display dish images

## API Usage and Limits

### Google Gemini API
- **Free Tier**: 15 requests per minute, 1500 requests per day
- **Paid Tier**: $0.00025 per 1K characters input, $0.0005 per 1K characters output
- **Rate Limits**: Varies by model and usage tier

## Troubleshooting

### Common Issues

1. **"API key not configured" error**
   - Ensure the API key is properly set in environment variables or Config.plist
   - Verify the API key is valid and not restricted

2. **Gemini API errors**
   - Check if Gemini API is enabled in your Google Cloud project
   - Verify the API key has access to Gemini API
   - Check rate limits and usage quotas

3. **No images found**
   - Check if the prompt is too specific
   - Check API usage limits

4. **Text extraction failures**
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

## Cost Optimization

1. **Cache results** to reduce API calls
2. **Use specific prompts** to improve result quality
3. **Monitor usage** to stay within free tier limits
4. **Optimize image quality** before sending to Gemini API to reduce processing costs

## Support

For API-related issues:
- [Google Gemini API Documentation](https://ai.google.dev/docs)
- [Google Cloud Console](https://console.cloud.google.com/)

For app-related issues:
- Check the app's error messages
- Review the console logs
- Ensure all configuration steps are completed 