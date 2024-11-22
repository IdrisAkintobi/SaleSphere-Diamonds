import { readdirSync, readFileSync, statSync, writeFileSync } from "fs";
import { join } from "path";

function mergeFacetAbis(inputDir: string, outputFile: string) {
  // Get all directories that end with 'Facet'
  const facetDirs = readdirSync(inputDir, { withFileTypes: true })
    .filter(
      (entry) =>
        entry.isDirectory() && // Check if it's a directory
        entry.name.endsWith("Facet.sol") // Filter for directories ending with 'Facet'
    )
    .map((entry) => join(inputDir, entry.name));

  const mergedAbi: any[] = [];

  for (const dir of facetDirs) {
    // Look for files ending with 'Facet.json' in each 'Facet' directory
    const facetFiles = readdirSync(dir)
      .filter(
        (file) =>
          file.endsWith("Facet.json") && // Files ending with 'Facet.json'
          statSync(join(dir, file)).isFile() // Ensure it's a file
      )
      .map((file) => join(dir, file));

    for (const file of facetFiles) {
      const content = JSON.parse(readFileSync(file, "utf-8"));
      if (content.abi) {
        mergedAbi.push(...content.abi);
      }
    }
  }

  // Remove duplicates
  const uniqueAbi = Array.from(
    new Map(mergedAbi.map((item) => [JSON.stringify(item), item])).values()
  );

  // Write the merged ABI to the output file
  writeFileSync(outputFile, JSON.stringify(uniqueAbi, null, 2));
  console.log(`Merged ABI written to ${outputFile}`);
}

// Paths
const inputDir = join(".", "out"); // Directory containing compiled contracts
const outputFile = join(".", "DiamondABI.json"); // Output file for merged ABI

// Run the merge
mergeFacetAbis(inputDir, outputFile);
