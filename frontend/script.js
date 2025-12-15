// URL de tu API Gateway (hardcoded por ahora, idealmente vendría de env vars en build time)
const API_URL = "https://86y7byy6gb.execute-api.us-east-1.amazonaws.com/prod/";

async function updateCounter() {
    const counterElement = document.getElementById("counter");

    try {
        // Hacemos POST para incrementar y obtener el nuevo valor
        const response = await fetch(API_URL, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            }
        });

        if (!response.ok) throw new Error("API Error");

        const data = await response.json();
        counterElement.innerText = data.count;
    } catch (error) {
        console.error("Error fetching count:", error);
        counterElement.innerText = "Error";
    }
}

// Llamar a la función al cargar la página
updateCounter();
