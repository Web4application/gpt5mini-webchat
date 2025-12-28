fetch("http://127.0.0.1:8000/predict", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ features: input.split(" ") })
})
.then(res => res.json())
.then(data => {
    aiResponse.textContent = `RODA AI: ${data.prediction}`;
})
.catch(err => {
    aiResponse.textContent = "Error: Could not get a response.";
});


