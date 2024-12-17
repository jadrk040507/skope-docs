# skope: The Economic Observatory by Universidad Panamericana

Welcome to SKOPE! This repository hosts two main components:

1. A website built using [Hugo](https://gohugo.io/) and the [Hextra theme](https://themes.gohugo.io/themes/hextra/).
2. Scripts for automated data updates using GitHub Actions.

---

## Website

The SKOPE website is hosted at [https://skope-docs.economiaup.com/](https://skope-docs.economiaup.com/) and serves as an economic observatory. Key details include:

### Features:

- **Static Pages**: Informative pages about the observatory and its goals.
- **Blog**: Regular updates and analyses related to economic data.
- **Documentation**: A dedicated section to explain the theoretical framework for time series manipulation and provide in-depth economic analysis.

### Technical Details:

- **Markdown and R Markdown**: Content is written in `.md` or `.Rmd` files.
- **Shortcodes**: Utilizes Hugo and Hextra shortcodes along with custom CSS for styling.
- **Build Process**: No need to build the site manually in RStudio. GitHub Actions automatically generate the HTML files in the `public` folder upon commit.
- **Hosting**: The website is hosted via GitHub Pages, with a custom subdomain configured through a `CNAME` file.

---

## Scripts

The repository includes scripts for fetching and updating datasets directly from various statistical sources. These scripts run automatically every 30 minutes using GitHub Actions.

### Features:

- **Data Sources**: Leverages R libraries to pull data from:
  - INEGI
  - Banxico
  - FRED
  - OCDE
  - World Bank
- **Environment Variables**: API keys and other sensitive information are stored in the GitHub repository's `Secrets`. These variables are accessed in the R scripts using `Sys.getenv("MY_VAR")`.
- **Automation**: GitHub Actions ensure datasets are always up-to-date without manual intervention.

### Folder Structure:

- **`scripts/`**: Contains all R scripts for data processing and updates.

---

## Contributing

We welcome contributions! Please submit issues or pull requests to improve the site or scripts.

### Guidelines:

- For website updates, ensure content follows Markdown or R Markdown standards.
- For scripts, test thoroughly to avoid disrupting automated updates.
- Contribution buttons are enabled at:
  - [GitHub Sponsors](https://github.com/sponsors/jadrk040507)
  - [Buy Me a Coffee](https://buymeacoffee.com/jadrk040507)

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

Special thanks to the Universidad Panamericana for supporting this initiative and to the creators of Hugo, the Hextra theme, and the R libraries used in this project.

