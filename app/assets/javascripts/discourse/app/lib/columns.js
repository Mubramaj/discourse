/**
 * Turns an element containing multiple children into a grid of columns.
 * Can be used to arrange images or media in a grid.
 *
 * Inspired/adapted from https://github.com/mladenilic/columns.js
 *
 * TODO: Add unit tests
 */
export default class Columns {
  constructor(container, options = {}) {
    this.container = container;

    this.options = {
      columns: 3,
      columnClass: "d-image-grid-column",
      minCount: 2,
      ...options,
    };

    this.excluded = ["BR", "P"];

    this.items = this._prepareItems();

    if (this.items.length >= this.options.minCount) {
      this.render();
    } else {
      container.dataset.disabled = true;
    }
  }

  count() {
    // a 2x2 grid looks better in most cases for 2 or 4 items
    if (this.items.length === 4 || this.items.length === 2) {
      return 2;
    }
    return this.options.columns;
  }

  render() {
    if (this.container.dataset.columns) {
      return;
    }

    this.container.dataset.columns = this.count();

    const columns = this._distributeEvenly();

    while (this.container.firstChild) {
      this.container.removeChild(this.container.firstChild);
    }
    this.container.append(...columns);
    return this;
  }

  _prepareColumns(count) {
    const columns = [];
    [...Array(count)].forEach(() => {
      const column = document.createElement("div");
      column.classList.add(this.options.columnClass);
      columns.push(column);
    });

    return columns;
  }

  _prepareItems() {
    let targets = [];

    Array.from(this.container.children).forEach((child) => {
      if (child.nodeName === "P" && child.children.length > 0) {
        // sometimes children are wrapped in a paragraph
        targets.push(...child.children);
      } else {
        targets.push(child);
      }
    });

    return targets.filter((item) => {
      return !this.excluded.includes(item.nodeName);
    });
  }

  _distributeEvenly() {
    const count = this.count();
    const columns = this._prepareColumns(count);

    const columnHeights = [];
    for (let n = 0; n < count; n++) {
      columnHeights[n] = 0;
    }
    this.items.forEach((item) => {
      let shortest = 0;

      for (let j = 1; j < count; ++j) {
        if (columnHeights[j] < columnHeights[shortest]) {
          shortest = j;
        }
      }

      // use aspect ratio to compare heights and append to shortest column
      // if element is not an image, assue ratio is 1:1
      const img = item.querySelector("img") || item;
      const aR = img.nodeName === "IMG" ? img.height / img.width : 1;
      columnHeights[shortest] += aR;
      columns[shortest].append(item);
    });

    return columns;
  }
}
