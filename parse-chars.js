#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const dirPath = process.argv[2];

if (!dirPath) {
  console.error('Usage: node char-frequency.js <directory_path>');
  process.exit(1);
}

const frequency = {};

function processFile(filePath) {
    console.log(`Processing ${filePath}`);
  const content = fs.readFileSync(filePath, 'utf8');
  for (const char of content) {
    frequency[char] = (frequency[char] || 0) + 1;
  }
}

function walkDirectory(currentPath) {
  const entries = fs.readdirSync(currentPath, { withFileTypes: true });

  for (const entry of entries) {
    if(entry.name.startsWith(".")) continue;
    const fullPath = path.join(currentPath, entry.name);
    if (entry.isDirectory()) {
      walkDirectory(fullPath);
    } else if (entry.isFile()) {
      try {
        const content = fs.readFileSync(fullPath);
        const isUtf8 = content.toString('utf8').length > 0;
        if (isUtf8) {
          processFile(fullPath);
        }
      } catch (err) {
        console.warn(`Skipping file (read error): ${fullPath}`);
      }
    }
  }
}

walkDirectory(dirPath);

// Sort and display results
const sorted = Object.entries(frequency).sort((a, b) => b[1] - a[1]);
for (const [char, count] of sorted) {
  if(count <= 10) continue;
  const displayChar = char === '\n' ? '\\n' : char === ' ' ? '[space]' : char;
  console.log(`'${displayChar}': ${count}`);
}

