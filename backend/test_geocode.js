const test = async () => {
    const url = new URL('https://nominatim.openstreetmap.org/search');
    url.searchParams.set('q', 'Mirpur 10, Dhaka');
    url.searchParams.set('format', 'json');
    url.searchParams.set('limit', '1');
    try {
        const res = await fetch(url.toString(), {
            headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36 FoodDeliveryApp/1.0' },
        });
        const text = await res.text();
        console.log("Status:", res.status);
        console.log("Text:", text);
    } catch (err) {
        console.error("Error: ", err);
    }
}
test();
