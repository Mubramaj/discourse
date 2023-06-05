import Component from "@glimmer/component";
import { formatUsername } from "discourse/lib/utilities";
import getURL from "discourse-common/lib/get-url";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";

export default class AssistantItem extends Component {
  @service search;
  @service appEvents;

  icon = this.args.icon || "search";

  get href() {
    let href = "#";
    if (this.args.category) {
      href = this.args.category.url;

      if (this.args.tags && this.args.isIntersection) {
        href = getURL(`/tag/${this.args.tag}`);
      }
    } else if (
      this.args.tags &&
      this.args.isIntersection &&
      this.args.additionalTags?.length
    ) {
      href = getURL(`/tag/${this.args.tag}`);
    }

    return href;
  }

  get prefix() {
    return this.args.prefix?.trim();
  }

  get formattedUsername() {
    return formatUsername(this.args.user.username);
  }

  // this could be renamed to something more practical
  get tags() {
    if (!this.args.tag || !this.args.additionalTags) {
      return;
    }

    return `tags:${[this.args.tag, ...this.args.additionalTags].join("+")}`;
  }

  @action
  onKeyup(e) {
    if (e.key === "Escape") {
      document.querySelector("#search-button").focus();
      this.args.closeSearchMenu();
      e.preventDefault();
      return false;
    }
    this.search.handleArrowUpOrDown(e);
  }

  //click(e) {
  //const searchInput = document.querySelector("#search-term");
  //searchInput.value = this.attrs.slug;
  //searchInput.focus();
  //this.sendWidgetAction("triggerAutocomplete", {
  //value: this.attrs.slug,
  //searchTopics: true,
  //setTopicContext: this.attrs.setTopicContext,
  //});
  //e.preventDefault();
  //return false;
  //}
}
