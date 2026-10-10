const http = require("http");
const PORT = process.env.PORT || 3000;
const GREETING = process.env.GREETING || "Hello from Docker v2";
http.createServer((req, res) => {
	if (req.url === "/health") {
		res.writeHead(200);
		return res.end("ok");
	}
	res.end(`${GREETING} | env=${process.env.APP_ENV || "dev"}\n`);
}).listen(PORT, "0.0.0.0", () => console.log(`listening on ${PORT}`));
