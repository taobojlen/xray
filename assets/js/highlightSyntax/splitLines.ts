/**
 * Shamelessly copied from https://github.com/PrismJS/prism/issues/2671
 */

import Prism, { Token } from "prismjs";

function wrapContent(
  content: Array<Token | string> | Token | string
): Array<Token | string> {
  return Array.isArray(content) ? content : [content];
}

function unwrapContent(
  content: Array<Token | string>
): Array<Token | string> | string {
  if (content.length === 0) {
    return "";
  } else if (content.length === 1 && typeof content[0] === "string") {
    return content[0];
  }

  return content;
}

function splitLinesRec(
  tokens: Array<Token | string>
): Array<Array<Token | string>> {
  let currentLine: Array<Token | string> = [];
  const lines: Array<Array<Token | string>> = [currentLine];
  for (let i = 0; i < tokens.length; i++) {
    const token = tokens[i];
    if (typeof token === "string") {
      const split = token.split(/\r\n|\r|\n/);
      for (let j = 0; j < split.length; j++) {
        if (j > 0) {
          lines.push((currentLine = []));
        }

        const token1 = split[j];
        if (token1) {
          currentLine.push(token1);
        }
      }
    } else {
      const split = splitLinesRec(wrapContent(token.content));
      if (split.length > 1) {
        for (let j = 0; j < split.length; j++) {
          if (j > 0) {
            lines.push((currentLine = []));
          }

          const line = split[j];
          if (line.length) {
            const token1 = new Prism.Token(
              token.type,
              unwrapContent(line),
              token.alias
            );
            token1.length = line.reduce((l, t) => l + t.length, 0);
            currentLine.push(token1);
          }
        }
      } else {
        currentLine.push(token);
      }
    }
  }

  return lines;
}

export default function (
  tokens: Array<Token | string>
): Array<Array<Token | string>> {
  const lines = splitLinesRec(tokens);
  // Dealing with trailing newlines
  if (!lines[lines.length - 1].length) {
    lines.pop();
  }

  return lines;
}