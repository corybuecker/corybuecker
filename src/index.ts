import { cp, readdir, readFile, writeFile, mkdir, rm } from "fs/promises";
import { readFileSync } from "fs";
import { exit } from "process";
import { marked } from "marked";
import YAML from "yaml";
import Handlebars from "handlebars";
import { createHash } from "crypto";

const copyStatic = async () => {
  return cp("assets/static", "output/", { recursive: true });
};

interface FrontMatter {
  [key: string]: string | undefined;

  slug: string;
  title: string;
  preview: string;
  description?: string;
  published: string;
  revised?: string;
}

Handlebars.registerHelper("integrity", function (fileName: string): string {
  const fileContents: string = readFileSync(`output/${fileName}`, {
    encoding: "utf8",
  });

  const hash = `sha384-${createHash("sha384")
    .update(fileContents)
    .digest("base64")}`;

  return hash;
});

Handlebars.registerHelper("fingerprint", function (fileName: string): string {
  const fileContents: string = readFileSync(`output/${fileName}`, {
    encoding: "utf8",
  });

  const hash = `/${fileName}?${createHash("sha384")
    .update(fileContents)
    .digest("hex")}`;

  return hash;
});

const readFiles = async () => {
  const files = await readdir("content");

  await rm("output/post", { recursive: true });
  await mkdir("output/post");

  for (const filePath of Array.from(files)) {
    console.log(filePath);
    const fileContents = await readFile(`content/${filePath}`, {
      encoding: "utf8",
    });
    const [, rawFrontMatter, rawContent] = fileContents.split("---");

    if (rawFrontMatter === undefined) throw new Error();
    const frontMatter: FrontMatter = YAML.parse(rawFrontMatter) as FrontMatter;

    if (rawContent === undefined) throw new Error();
    const content = marked(rawContent);
    const rawPage = await readFile("templates/page.html.hbs", {
      encoding: "utf8",
    });
    const pageTemplate = Handlebars.compile(rawPage);

    await mkdir(`output/post/${frontMatter.slug}`);

    await writeFile(
      `output/post/${frontMatter.slug}/index.html`,
      pageTemplate({ ...frontMatter, body: content })
    );
  }

  return files;
};

const homepage = async () => {
  const files = await readdir("content");
  const [homepagePath, ...otherPaths] = files.sort().reverse();

  if (homepagePath === undefined) throw new Error();

  const rawPage = await readFile("templates/homepage.html.hbs", {
    encoding: "utf8",
  });
  const pageTemplate = Handlebars.compile(rawPage);

  const fileContents = await readFile(`content/${homepagePath}`, {
    encoding: "utf8",
  });

  const [, rawFrontMatter, rawContent] = fileContents.split("---");

  if (rawFrontMatter === undefined) throw new Error();
  const frontMatter = YAML.parse(rawFrontMatter) as FrontMatter;

  if (rawContent === undefined) throw new Error();
  const content = marked(rawContent);

  const otherPages = [];
  for (const filePath of Array.from(otherPaths)) {
    console.log(filePath);
    const fileContents = await readFile(`content/${filePath}`, {
      encoding: "utf8",
    });

    const [, rawFrontMatter] = fileContents.split("---");

    if (rawFrontMatter === undefined) throw new Error();
    const frontMatter = YAML.parse(rawFrontMatter) as FrontMatter;

    otherPages.push({
      title: frontMatter.title,
      slug: frontMatter.slug,
    });
  }

  console.log(otherPages);

  await writeFile(
    `output/index.html`,
    pageTemplate({ ...frontMatter, body: content, otherPages })
  );

  return files;
};

Promise.resolve(copyStatic())
  .then(() => Promise.all([readFiles(), homepage()]))
  .then(() => exit(0))
  .catch((error) => {
    console.error(error);
    exit(1);
  });
