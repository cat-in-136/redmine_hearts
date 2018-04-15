$(function() {
  "use strict";

  $(".journal-heart-holder > .heart-link-with-count").each(function () {
    let link = this;
    let heartable_subject;
    let num_insert = 0;
    $.each(link.classList, function () {
      let klass = this;
      if (/^([-a-z0-9]+-[0-9]+)-heart$/.test(klass)) {
        heartable_subject = RegExp.$1;
      }
    });

    if (num_insert === 0) {
      let note_subject = heartable_subject.replace(/^[-a-z0-9]+-/, "journal-") + "-notes";
      num_insert += $(link).insertBefore($("#" + note_subject + " .contextual :first-child")).length;
    }
    if (num_insert === 0) {
      let journal_subject = heartable_subject.replace(/^[-a-z0-9]+-/, "change-");
      num_insert += $(link).appendTo($("#" + journal_subject)).length;
      if (num_insert > 0) { $(link).wrap('<div class="contextual"></div>'); }
    }

    if (num_insert === 0) {
      console.debug("Failed to transplant : " + link);
    }
  });
  $("#content > .heart-link-with-count, #main > .heart-link-with-count, .replies-heart-holder > .heart-link-with-count").each(function () {
    let link = this;
    let heartable_subject;
    let num_insert = 0;
    $.each(link.classList, function () {
      let klass = this;
      if (/^([-a-z0-9]+-[0-9]+)-heart$/.test(klass)) {
        heartable_subject = RegExp.$1;
      }
    });

    // insert immediate after the corresponding watcher links.
    if (num_insert === 0) {
      let watcher_klass = heartable_subject + "-watcher";
      num_insert += $(link).insertAfter("." + watcher_klass).length;
    }

    // append to contextual within the corresponding items.
    if (num_insert === 0) {
      num_insert += $(link).appendTo("#" + heartable_subject + " .contextual").length;
    }

    // append to contextual of the children of the content.
    if (num_insert === 0) {
      num_insert += $(link).appendTo("#content > .contextual").length;
    }

    if (num_insert === 0) {
      console.debug("Failed to transplant : ." + heartable_subject + "-heart");
    }
  });
});
