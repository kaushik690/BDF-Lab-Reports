const sqlite3 = require("sqlite3");
const { open } = require("sqlite");
const path = require("path");

const dbPath = path.join(__dirname, "books.db");

async function setupDatabase() {
  const db = await open({
    filename: dbPath,
    driver: sqlite3.Database,
  });

  await db.exec(`
    CREATE TABLE IF NOT EXISTS book (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      author TEXT NOT NULL,
      price INTEGER NOT NULL,
      pages INTEGER NOT NULL
    );
  `);

  const existing = await db.get("SELECT COUNT(*) as count FROM book");
  if (existing.count === 0) {
    await db.run(
      "INSERT INTO book (title, author, price, pages) VALUES (?, ?, ?, ?)",
      ["The Pragmatic Programmer", "Andrew Hunt", 450, 352]
    );
    await db.run(
      "INSERT INTO book (title, author, price, pages) VALUES (?, ?, ?, ?)",
      ["Clean Code", "Robert C. Martin", 399, 464]
    );
    await db.run(
      "INSERT INTO book (title, author, price, pages) VALUES (?, ?, ?, ?)",
      ["The Art of Computer Programming", "Donald Knuth", 799, 672]
    );
    await db.run(
      "INSERT INTO book (title, author, price, pages) VALUES (?, ?, ?, ?)",
      ["Introduction to Algorithms", "Thomas Cormen", 650, 1312]
    );
    await db.run(
      "INSERT INTO book (title, author, price, pages) VALUES (?, ?, ?, ?)",
      ["Design Patterns", "Gang of Four", 550, 395]
    );
    await db.run(
      "INSERT INTO book (title, author, price, pages) VALUES (?, ?, ?, ?)",
      ["You Don't Know JS", "Kyle Simpson", 299, 278]
    );
    await db.run(
      "INSERT INTO book (title, author, price, pages) VALUES (?, ?, ?, ?)",
      ["The Mythical Man-Month", "Frederick Brooks", 375, 336]
    );
    await db.run(
      "INSERT INTO book (title, author, price, pages) VALUES (?, ?, ?, ?)",
      ["Refactoring", "Martin Fowler", 499, 448]
    );
    await db.run(
      "INSERT INTO book (title, author, price, pages) VALUES (?, ?, ?, ?)",
      ["The Clean Coder", "Robert C. Martin", 320, 256]
    );
    await db.run(
      "INSERT INTO book (title, author, price, pages) VALUES (?, ?, ?, ?)",
      ["Structure and Interpretation", "Harold Abelson", 580, 657]
    );
    console.log("Database seeded with 10 books.");
  } else {
    console.log("Database already has data, skipping seed.");
  }

  await db.close();
  console.log("Database setup complete.");
}

setupDatabase().catch((err) => {
  console.error("Setup failed:", err);
  process.exit(1);
});
