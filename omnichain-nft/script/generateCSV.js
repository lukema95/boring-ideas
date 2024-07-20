const fs = require('fs');

function generateMondrianStyleCSV() {
  let csvContent = 'x,y,color\n';

  // Define the dimensions of the grid
  const gridSize = 400;
  const cellSize = 100;

  // Iterate through the grid
  for (let x = 0; x < gridSize; x += cellSize) {
    for (let y = 0; y < gridSize; y += cellSize) {
      // Randomly choose the color based on a simple condition
      const randomValue = Math.random();
      let color;
      
      if (randomValue < 0.33) {
        color = '#FF0000'; // Red
      } else if (randomValue < 0.66) {
        color = '#FFFF00'; // Yellow
      } else {
        color = '#0000FF'; // Blue
      }
      
      // Append the CSV data for each cell
      csvContent += `${x},${y},${color}\n`;
    }
  }

  return csvContent;
}

function saveCSVToFile() {
  const csvData = generateMondrianStyleCSV();

  fs.writeFile('mondrian_style.csv', csvData, (err) => {
    if (err) {
      console.error('Error writing CSV file:', err);
    } else {
      console.log('CSV file saved as mondrian_style.csv');
    }
  });
}

saveCSVToFile();
