import { GoogleGenerativeAI } from "@google/generative-ai";
import { Hono } from "hono";
import { handle } from "hono/vercel";
import { Client, Databases, ID, Storage } from "node-appwrite";

const {
  APPWRITE_API_KEY,
  APPWRITE_PROJECT_ID,
  APPWRITE_DATABASE_ID,
  APPWRITE_STORAGE_ID,
  APPWRITE_COLLECTION_ID,
  GEMINI_API_KEY,
} = process.env;

if (!APPWRITE_API_KEY) {
  throw new Error("Missing Appwrite environment variables");
}

if (!APPWRITE_PROJECT_ID) {
  throw new Error("Missing Appwrite environment variables");
}

if (!APPWRITE_DATABASE_ID) {
  throw new Error("Missing Appwrite environment variables");
}

if (!APPWRITE_STORAGE_ID) {
  throw new Error("Missing Appwrite environment variables");
}

if (!APPWRITE_COLLECTION_ID) {
  throw new Error("Missing Appwrite environment variables");
}

if (!GEMINI_API_KEY) {
  throw new Error("Missing Gemini environment variables");
}

const client = new Client()
  .setProject(APPWRITE_PROJECT_ID)
  .setKey(APPWRITE_API_KEY);

const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

const storage = new Storage(client);
const database = new Databases(client);

const app = new Hono().basePath('/api');

app.get("/", (c) => {
  return c.json({
    data: "Welcome to the Appwrite Storage API",
  });
});

app.get("/files", async (c) => {
  const { files, total } = await storage.listFiles(APPWRITE_STORAGE_ID);
  return c.json({ data: files, total });
});

app.get("/files/:fileId", async (c) => {
  const { fileId } = c.req.param();
  const file = await storage.getFile(APPWRITE_STORAGE_ID, fileId);
  return c.json({ data: file });
});

app.post("/files", async (c) => {
  const formData = await c.req.formData();
  const file = formData.get("file") as File | null;

  if (!file) {
    return c.json({ error: "File not found" }, 400);
  }

  const fileId = await storage.createFile(
    APPWRITE_STORAGE_ID,
    ID.unique(),
    file
  );

  return c.json({ data: fileId });
});

app.post("/notes", async (c) => {
  const { title, content } = await c.req.json();

  if (!title || !content) {
    return c.json({ error: "Title and content are required" }, 400);
  }

  const noteId = ID.unique();

  const note = {
    title,
    content,
  };

  const createdNote = await database.createDocument(
    APPWRITE_DATABASE_ID,
    APPWRITE_COLLECTION_ID,
    noteId,
    note
  );

  return c.json({ data: createdNote });
});

app.get("/notes", async (c) => {
  const { documents, total } = await database.listDocuments(
    APPWRITE_DATABASE_ID,
    APPWRITE_COLLECTION_ID
  );
  return c.json({ data: documents, total });
});

app.get("/notes/:noteId", async (c) => {
  const { noteId } = c.req.param();
  const note = await database.getDocument(
    APPWRITE_DATABASE_ID,
    APPWRITE_COLLECTION_ID,
    noteId
  );
  return c.json({ data: note });
});

app.put("/notes/:noteId", async (c) => {
  const { noteId } = c.req.param();
  const formData = await c.req.formData();
  const title = formData.get("title") as string | null;
  const content = formData.get("content") as string | null;

  if (!title || !content) {
    return c.json({ error: "Title and content are required" }, 400);
  }

  const note = {
    title,
    content,
  };

  const updatedNote = await database.updateDocument(
    APPWRITE_DATABASE_ID,
    APPWRITE_COLLECTION_ID,
    noteId,
    note
  );

  return c.json({ data: updatedNote });
});

app.delete("/notes/:noteId", async (c) => {
  const { noteId } = c.req.param();
  await database.deleteDocument(
    APPWRITE_DATABASE_ID,
    APPWRITE_COLLECTION_ID,
    noteId
  );
  return c.json({ message: "Note deleted" });
});

app.delete("/files/:fileId", async (c) => {
  const { fileId } = c.req.param();
  await storage.deleteFile(APPWRITE_STORAGE_ID, fileId);
  return c.json({ message: "File deleted" });
});

app.get("/files/:fileId/download", async (c) => {
  const { fileId } = c.req.param();
  const fileDetails = await storage.getFile(APPWRITE_STORAGE_ID, fileId);
  const file = await storage.getFileDownload(APPWRITE_STORAGE_ID, fileId);
  return new Response(file, {
    headers: {
      "Content-Disposition": `attachment; filename="${fileDetails.name}"`,
      "Content-Type": fileDetails.mimeType,
    },
  });
});

app.get("/files/:fileId/preview", async (c) => {
  const { fileId } = c.req.param();
  const fileDetails = await storage.getFile(APPWRITE_STORAGE_ID, fileId);
  const file = await storage.getFilePreview(APPWRITE_STORAGE_ID, fileId);
  return new Response(file, {
    headers: {
      "Content-Disposition": `inline; filename="${fileDetails.name}"`,
      "Content-Type": fileDetails.mimeType,
    },
  });
});

app.post("/generate", async (c) => {
  const body = await c.req.json();
  const { prompt, content } = body;

  if (!prompt) {
    return c.json({ error: "Prompt is required" }, 400);
  }

  if (!content) {
    return c.json({ error: "Content is required" }, 400);
  }

  const result = await model.generateContent({
    systemInstruction: `**Context:**
You are tasked with rephrase the content based on the user's input and generating HTML content compatible with \`NSAttributedString\`. The HTML should preserve text formatting, and images should be embedded using URLs within the text. The input will contain both text and image URLs.

**Requirements:**
1. Rephrase the content to be more engaging and clear.
2. Detail the documentation and based on the user's input.
3. The HTML should be structured correctly and valid.
4. Text formatting should be preserved:
   - **Bold** text should use \`<b>\` or \`<strong>\` tags.
   - *Italic* text should use \`<i>\` or \`<em>\` tags.
   - Links should be wrapped in \`<a href="URL">\` tags.
   - Images should be inserted using \`<img src="IMAGE_URL" alt="description" width="300" />\`.
5. The HTML output must be simple and compatible with \`NSAttributedString\` (avoid inline styles where possible).
6. Each image URL provided should be inserted into the HTML with an \`<img>\` tag.
7. Ensure the structure is complete, including the \`<html>\`, \`<head>\`, and \`<body>\` tags.

**Input Format:**
The input consists of text blocks with embedded image URLs. The image URLs need to be converted into proper \`<img>\` tags within the HTML.

**Example Input:**

\`\`\`
Repudiandae modi quam rerum adipisci non. A quia ex cupiditate error. Sunt qui fugiat dolorem sint laborum est nihil. Tenetur molestiae autem aspernatur perferendis qui.

Sit consequatur delectus eos voluptatem ratione vel vero. Dolorem pariatur iusto rerum nesciunt. Ut id ut possimus. Accusamus aperiam autem laudantium.

http://localhost:3000/files/whatever/download

Repudiandae modi quam rerum adipisci non. A quia ex cupiditate error. Sunt qui fugiat dolorem sint laborum est nihil. Tenetur molestiae autem aspernatur perferendis qui.

http://localhost:3000/files/whatever/download

Thank you!
\`\`\`

**Task:**
Generate an HTML response that incorporates the text and images. Convert the URLs into \`<img>\` tags and ensure the text and images are appropriately formatted.

---

**Expected Output Example (HTML):**

\`\`\`html
<html>
<head>
    <style>
        body { font-family: Helvetica, Arial, sans-serif; }
    </style>
</head>
<body>
    <p>Repudiandae modi quam rerum adipisci non. A quia ex cupiditate error. Sunt qui fugiat dolorem sint laborum est nihil. Tenetur molestiae autem aspernatur perferendis qui.</p>
    <p>Sit consequatur delectus eos voluptatem ratione vel vero. Dolorem pariatur iusto rerum nesciunt. Ut id ut possimus. Accusamus aperiam autem laudantium.</p>

    <p><img src="http://localhost:3000/files/67e1e15a00098960758c/download" alt="image1" /></p>

    <p>Repudiandae modi quam rerum adipisci non. A quia ex cupiditate error. Sunt qui fugiat dolorem sint laborum est nihil. Tenetur molestiae autem aspernatur perferendis qui.</p>

    <p><img src="http://localhost:3000/files/67e1e15a00098960758c/download" alt="image2" /></p>

    <p>Thank you!</p>
</body>
</html>
\`\`\`

---

### Key Notes:
1. The image URLs are placed inside \`<img>\` tags.
2. The text is preserved as paragraphs (\`<p>\` tags).
3. The HTML is simple and compatible with \`NSAttributedString\`.

This prompt will guide Gemini to generate the correct HTML content for the text and image URLs you provide. Feel free to modify the input text and image URLs accordingly.`,
    contents: [
      {
        role: "user",
        parts: [
          {
            text: `**Input:**
            ${prompt}

            **Content:**
            ${content}`,
          },
        ],
      },
    ],
    generationConfig: {
      responseMimeType: "text/plain",
      temperature: 1,
      topP: 0.95,
      topK: 40,
      maxOutputTokens: 20000,
    },
  });

  let generatedText = result.response.text();
  if (generatedText.startsWith("```") && generatedText.endsWith("```")) {
    generatedText = generatedText.slice(7, -3);
  }

  return c.html(generatedText);
});

export const GET = handle(app);
export const POST = handle(app);
export const PUT = handle(app);
export const DELETE = handle(app);
export const PATCH = handle(app);
export const OPTIONS = handle(app);
export const HEAD = handle(app);