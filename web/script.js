document.addEventListener('DOMContentLoaded', () => {
    const menuImageUpload = document.getElementById('menuImageUpload');
    const imagePreview = document.getElementById('imagePreview');
    const imagePreviewContainer = document.getElementById('image-preview-container');
    const messageArea = document.getElementById('messageArea');
    const analyzeMenuButton = document.getElementById('analyzeMenuButton');
    const menuDisplaySection = document.getElementById('menu-display-section');
    const menuItemsContainer = document.getElementById('menuItemsContainer');

    let uploadedFile = null;

    menuImageUpload.addEventListener('change', (event) => {
        uploadedFile = event.target.files[0];
        if (uploadedFile) {
            const reader = new FileReader();
            reader.onload = (e) => {
                imagePreview.src = e.target.result;
                imagePreview.style.display = 'block';
                analyzeMenuButton.style.display = 'inline-block';
                messageArea.textContent = ''; // Clear previous messages
                menuDisplaySection.style.display = 'none'; // Hide previous results
                menuItemsContainer.innerHTML = ''; // Clear previous items
            }
            reader.readAsDataURL(uploadedFile);
        } else {
            imagePreview.style.display = 'none';
            analyzeMenuButton.style.display = 'none';
            uploadedFile = null;
        }
    });

    analyzeMenuButton.addEventListener('click', async () => {
        if (!uploadedFile) {
            messageArea.textContent = 'Please upload an image first.';
            messageArea.className = 'message error';
            return;
        }

        messageArea.textContent = 'Analyzing menu... please wait.';
        messageArea.className = 'message info';
        menuDisplaySection.style.display = 'none';
        menuItemsContainer.innerHTML = '';

        try {
            // 1. Menu Detection (Placeholder)
            const isMenu = await detectMenu(uploadedFile);
            if (!isMenu) {
                messageArea.textContent = 'The uploaded image does not appear to be a menu.';
                messageArea.className = 'message error';
                return;
            }
            messageArea.textContent = 'Menu detected! Parsing items...';
            messageArea.className = 'message info';

            // 2. Menu Parsing (Placeholder - using Tesseract.js for a basic attempt)
            const dishNames = await parseMenu(uploadedFile);
            if (!dishNames || dishNames.length === 0) {
                messageArea.textContent = 'Could not parse any dish names from the menu.';
                messageArea.className = 'message error';
                return;
            }
            messageArea.textContent = `Found ${dishNames.length} potential dishes. Searching for images...`;

            // 3. Search for dish images and display
            await displayMenuWithImages(dishNames);
            messageArea.textContent = 'Menu visualized!';
            messageArea.className = 'message success';
            menuDisplaySection.style.display = 'block';

        } catch (error) {
            console.error('Error during menu analysis:', error);
            messageArea.textContent = `An error occurred: ${error.message}`;
            messageArea.className = 'message error';
        }
    });

    async function detectMenu(imageFile) {
        // Placeholder: In a real app, this would involve more sophisticated ML analysis.
        // For now, we'll assume any uploaded image with reasonable text content is a menu.
        // This could be a call to a backend service or more advanced client-side model.
        messageArea.textContent = 'Detecting menu (simulated)...';
        await new Promise(resolve => setTimeout(resolve, 500)); // Simulate delay

        // Basic check: if it's an image, let's try to OCR it. If OCR yields some text, assume it's a menu.
        // This is a very rough heuristic.
        const textContent = await ocrImage(imageFile, true); // true for silent mode during detection
        if (textContent && textContent.length > 20) { // Arbitrary length check
             console.log("Menu detection: Found text, assuming it's a menu.");
            return true;
        } else {
            console.log("Menu detection: Not enough text found, assuming not a menu.");
            return false;
        }
    }

    async function ocrImage(imageFile, silent = false) {
        if (!Tesseract) {
            if (!silent) messageArea.textContent = 'OCR library (Tesseract.js) not loaded. Please ensure you have an internet connection and try again. For now, using dummy data.';
            console.error("Tesseract.js not loaded.");
             // Fallback to dummy data if Tesseract is not available.
            return "Dummy Dish 1\nAnother Item\nSpecial Pasta";
        }
        if (!silent) messageArea.textContent = 'Performing OCR (this may take a moment)...';

        const worker = await Tesseract.createWorker();
        await worker.loadLanguage('eng');
        await worker.initialize('eng');
        const { data: { text } } = await worker.recognize(imageFile);
        await worker.terminate();
        if (!silent) console.log("OCR Result:", text);
        return text;
    }

    async function parseMenu(imageFile) {
        // Placeholder: Uses OCR (Tesseract.js) and then splits lines.
        // This is a very naive approach. Real menu parsing is much more complex.
        const ocrText = await ocrImage(imageFile);
        if (!ocrText) return [];

        return ocrText.split('\n').map(line => line.trim()).filter(line => line.length > 2 && isNaN(line)); // Filter out empty lines, short lines, and lines that are just numbers (prices)
    }

    async function displayMenuWithImages(dishNames) {
        menuItemsContainer.innerHTML = ''; // Clear previous items

        for (const name of dishNames) {
            const itemView = document.createElement('div');
            itemView.className = 'menu-item';

            const nameElement = document.createElement('h3');
            nameElement.textContent = name;
            itemView.appendChild(nameElement);

            const imageElement = document.createElement('img');
            imageElement.alt = `Image of ${name}`;
            imageElement.style.display = 'none'; // Hide until loaded
            itemView.appendChild(imageElement);

            const imageStatusElement = document.createElement('p');
            imageStatusElement.textContent = 'Searching for image...';
            itemView.appendChild(imageStatusElement);

            // 4. Search online for this restaurant's pictures of the dishes. (Placeholder API)
            // IMPORTANT: Replace with your actual image search API details.
            // Exposing API keys on the client-side is insecure for many APIs (e.g., Google Custom Search).
            // A backend proxy is the recommended approach for production.
            // Using a free API like Pexels or Unsplash for demo purposes if their terms allow.
            // For this example, let's simulate with a placeholder.
            try {
                // const imageUrl = await searchImageOnline(name); // Replace with actual search
                const imageUrl = `https://source.unsplash.com/400x300/?${encodeURIComponent(name)}`; // Simple Unsplash source

                if (imageUrl) {
                    imageElement.onload = () => {
                        imageElement.style.display = 'block';
                        imageStatusElement.style.display = 'none'; // Hide "Searching..."
                    };
                    imageElement.onerror = () => {
                        imageElement.style.display = 'none';
                        imageStatusElement.textContent = 'Image not found or failed to load.';
                    };
                    imageElement.src = imageUrl;
                } else {
                    imageStatusElement.textContent = 'Image not found.';
                }
            } catch (err) {
                console.error(`Error fetching image for ${name}:`, err);
                imageStatusElement.textContent = 'Error finding image.';
            }
            menuItemsContainer.appendChild(itemView);
        }
    }

    // Placeholder for actual online image search
    // async function searchImageOnline(dishName) {
    //     // Replace with your actual API call, e.g., Google Custom Search, Bing, Pexels, Unsplash etc.
    //     // Ensure you handle API keys securely, ideally via a backend proxy.
    //     console.log(`Simulating image search for: ${dishName}`);
    //     // Example: const response = await fetch(`https://api.example.com/search?q=${dishName}&key=YOUR_API_KEY`);
    //     // const data = await response.json();
    //     // return data.items[0].imageUrl;
    //     await new Promise(resolve => setTimeout(resolve, 1000)); // Simulate network delay
    //
    //     // Dummy image URLs for testing - replace with actual search results
    //     const dummyImages = {
    //         "pizza": "https://via.placeholder.com/150/FF0000/FFFFFF?Text=Pizza",
    //         "pasta": "https://via.placeholder.com/150/00FF00/FFFFFF?Text=Pasta",
    //         "salad": "https://via.placeholder.com/150/0000FF/FFFFFF?Text=Salad"
    //     };
    //     const keyword = dishName.toLowerCase().split(" ")[0]; // very simple keyword extraction
    //     return dummyImages[keyword] || null; // Return a specific dummy image or null
    // }

});

// Load Tesseract.js - typically from a CDN
// Add this to your HTML or load it dynamically.
// <script src='https://unpkg.com/tesseract.js@5/dist/worker.min.js'></script>
// <script src='https://unpkg.com/tesseract.js@5/dist/tesseract.min.js'></script>
// For this script, we assume Tesseract is loaded globally.
// If not, the ocrImage function will use dummy data.
const tesseractScript = document.createElement('script');
tesseractScript.src = 'https://unpkg.com/tesseract.js@5/dist/tesseract.min.js';
tesseractScript.onload = () => {
    console.log('Tesseract.js loaded.');
};
tesseractScript.onerror = () => {
    console.error('Failed to load Tesseract.js. OCR will use dummy data.');
    // The script.js already has a fallback if Tesseract object is not found.
};
document.head.appendChild(tesseractScript);
