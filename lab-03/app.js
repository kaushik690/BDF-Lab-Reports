const express = require("express");
const sqlite3 = require("sqlite3");
const { open } = require("sqlite");
const path = require("path");

const app = express();
app.use(express.json());

const dbPath = path.join(__dirname, "books.db");
let db;

const initializeDBAndServer = async () => {
  db = await open({
    filename: dbPath,
    driver: sqlite3.Database,
  });

  app.listen(3000, () => {
    console.log("Server running at http://localhost:3000/");
  });
};

app.get("/books/", async (req, res) => {
  const {
    search_q = "",
    order_by = "id",
    order = "ASC",
    limit = 10,
    offset = 0,
    min_price = 0,
    max_price = 999999,
  } = req.query;

  const allowedOrderBy = ["id", "title", "author", "price", "pages"];
  const allowedOrder = ["ASC", "DESC"];

  const safeOrderBy = allowedOrderBy.includes(order_by) ? order_by : "id";
  const safeOrder = allowedOrder.includes(order.toUpperCase())
    ? order.toUpperCase()
    : "ASC";

  const query = `
    SELECT * FROM book
    WHERE title LIKE ?
    AND price BETWEEN ? AND ?
    ORDER BY ${safeOrderBy} ${safeOrder}
    LIMIT ? OFFSET ?
  `;

  const books = await db.all(query, [
    `%${search_q}%`,
    Number(min_price),
    Number(max_price),
    Number(limit),
    Number(offset),
  ]);

  res.status(200).json(books);
});

app.get("/books/:bookId/", async (req, res) => {
  const { bookId } = req.params;
  const book = await db.get("SELECT * FROM book WHERE id = ?", [bookId]);

  if (book === undefined) {
    res.status(404).json({ message: "Book Not Found" });
  } else {
    res.status(200).json(book);
  }
});

app.post("/books/", async (req, res) => {
  const { title, author, price, pages } = req.body;

  if (!title) {
    return res.status(400).json({ message: "Title is required" });
  }

  if (!author) {
    return res.status(400).json({ message: "Author is required" });
  }

  if (price === undefined || price === null || price === "") {
    return res.status(400).json({ message: "Price is required" });
  }

  if (typeof price !== "number" || isNaN(price) || price < 0) {
    return res
      .status(400)
      .json({ message: "Price must be a valid non-negative number" });
  }

  const result = await db.run(
    "INSERT INTO book (title, author, price, pages) VALUES (?, ?, ?, ?)",
    [title, author, price, pages || 0]
  );

  res
    .status(201)
    .json({ bookId: result.lastID, message: "Book Added Successfully" });
});

app.put("/books/:bookId/", async (req, res) => {
  const { bookId } = req.params;
  const { title, author, price, pages } = req.body;

  const existing = await db.get("SELECT * FROM book WHERE id = ?", [bookId]);
  if (existing === undefined) {
    return res.status(404).json({ message: "Book Not Found" });
  }

  if (!title) {
    return res.status(400).json({ message: "Title is required" });
  }

  if (!author) {
    return res.status(400).json({ message: "Author is required" });
  }

  if (price === undefined || price === null || price === "") {
    return res.status(400).json({ message: "Price is required" });
  }

  if (typeof price !== "number" || isNaN(price) || price < 0) {
    return res
      .status(400)
      .json({ message: "Price must be a valid non-negative number" });
  }

  await db.run(
    "UPDATE book SET title = ?, author = ?, price = ?, pages = ? WHERE id = ?",
    [title, author, price, pages || existing.pages, bookId]
  );

  res.status(200).json({ message: "Book Updated Successfully" });
});

app.delete("/books/:bookId/", async (req, res) => {
  const { bookId } = req.params;
  const existing = await db.get("SELECT * FROM book WHERE id = ?", [bookId]);

  if (existing === undefined) {
    return res.status(404).json({ message: "Book Not Found" });
  }

  await db.run("DELETE FROM book WHERE id = ?", [bookId]);
  res.status(200).json({ message: "Book Deleted Successfully" });
});

initializeDBAndServer();
