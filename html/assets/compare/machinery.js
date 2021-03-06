$(document).ready(function () {
  // Align content below floating menu
  var header_height =  $("#nav-bar").height() + 20;
  $("#content_container").css("margin-top", header_height);
  $("a.scope_anchor, a.both_anchor").css("height", header_height);
  $("a.scope_anchor, a.both_anchor").css("margin-top", -header_height);

  $('.scope_anchor').each(function(){
    var anchor = $(this);
    $(window).scroll(function() {
      setCurrentScopeState(anchor);
      highlightCurrentScope();
    })
  });

  // Show title on cut-off table elements
  $('.scope td').bind('mouseenter', function(){
    var $this = $(this);

    if(this.offsetWidth < this.scrollWidth && !$this.attr('title')){
        $this.attr('title', $this.text());
    }
  });

  // Hook up the toggle links
  $(".toggle").click(function(){
    $(this).closest(".scope").find(".scope_content").collapse("toggle");
    $(this).toggleClass("collapsed");
  });

  $("#collapse-all").click(function(){
    $(".scope_content").collapse("hide");
    $(".toggle").addClass("collapsed");
    $(this).hide();
    $("#expand-all").show();
  });

  $("#expand-all").click(function(){
    $(".scope_content").collapse("show");
    $(".toggle").removeClass("collapsed");
    $(this).hide();
    $("#collapse-all").show();
  });

  // Show or hide elements which are common in scope
  $(".show-common-elements").click(function(){
    $scope = $(this).closest(".scope");
    if ($scope.find(".toggle").hasClass("collapsed")){
      $scope.find(".scope_content").collapse("show");
      $scope.find(".toggle").removeClass("collapsed");
    }
    $scope.find(".scope_common_content").collapse("show");
    $scope.find(".scope_content").find(".show-common-elements").hide();
    $scope.find(".hide-common-elements").show();
    if ($(this).attr("href")){
      $('html,body').animate({scrollTop: $($(this).attr("href")).offset().top}, 'slow');
    }
    return false;
  });

  $(".hide-common-elements").click(function(){
    $scope = $(this).closest(".scope");
    $scope.find(".scope_common_content").collapse("hide");
    $(this).hide();
    $scope.find(".show-common-elements").show();
    return false;
  });

  $(".show-changed-elements").click(function(){
    $scope = $(this).closest(".scope");
    if ($scope.find(".toggle").hasClass("collapsed")){
      $scope.find(".scope_content").collapse("show");
      $scope.find(".toggle").removeClass("collapsed");
    }
    if ($(this).attr("href")){
      $('html,body').animate({scrollTop: $($(this).attr("href")).offset().top}, 'slow');
    }
    return false;
  });

  // Unmanaged files diffs
  $("#diff-unmanaged-files").on("show.bs.modal", function(e) {
    var trigger = $(e.relatedTarget);

    $("#diff-unmanaged-files-content").hide();
    $("#diff-unmanaged-files-error").hide();
    $("#diff-unmanaged-files-spinner").show();

    var description1 = $("body").data("description-a");
    var description2 = $("body").data("description-b");
    var url = "/compare/" + description1 + "/" + description2 + "/files/unmanaged_files" +
      trigger.data("file");
    $("#diff-unmanaged-files-file").text(trigger.data("file"));
    $.get(url, function(res) {
      $("#diff-unmanaged-files-spinner").hide();
        if(res.length === 0) {
          $("#diff-unmanaged-files-error").html("Files are equal.").show();
        } else {
          $("#diff-unmanaged-files-diff").html(res);
          $("#diff-unmanaged-files-content").show();
        }
      }, "text").
      error(function(res) {
        $("#diff-unmanaged-files-spinner").hide();
        if(res.readyState == 0) {
          $("#diff-unmanaged-files-error").html("Could not download file content. Is the web server still running?").show();
        } else if(res.status == 406) {
          $("#diff-unmanaged-files-error").html("Can't generate diff, the files are binary.").show();
        } else {
          $("#diff-unmanaged-files-error").html("There was an unknown error downloading the file.").show();
        }
      });
  });

  $('.scope_anchor').each(function(){
    var anchor = $(this);
    setCurrentScopeState(anchor);
  });
  highlightCurrentScope();
});

$(document).on("click", ".open-description-selector", function () {
  if ($(this).hasClass("show")) {
    descriptionName = $(".description-name:last").val();
    $(".description-selector-action").text("compare with description \"" + descriptionName + "\".");
    $("a.show-description").show();
    $("a.compare-description").hide();
  }else{
    descriptionName = $(".description-name:first").val();
    $(".description-selector-action").text("compare with description \"" + descriptionName + "\".");
    $("a.show-description").hide();
    $("a.compare-description").show();
  }
});

