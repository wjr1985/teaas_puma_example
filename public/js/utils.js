function fileInputs() {
  var $this = $(this),
      $val = $this.val(),
      valArray = $val.split('\\'),
      newVal = valArray[valArray.length-1],
      $button = $this.siblings('.btn'),
      $fakeFile = $this.siblings('.file-holder');
  if(newVal !== '') {
    $button.text('Image Chosen');
    if($fakeFile.length === 0) {
      $button.after('<p class="file-holder help-block">' + newVal + '</p>');
    } else {
      $fakeFile.text(newVal);
    }
  }
};

function retrieveSlackVars() {
  var localStoreStr = localStorage.getItem('teaas');
  if (!localStoreStr) {
    return;
  }
  var localStore = JSON.parse(localStoreStr);
  for (var instance in localStore) {
    $('select[name=slackSelector]').append("<option value='" + localStore[instance] + "'>" + instance + "</option>");
  }

  var slackToken = localStorage.getItem('slackToken');
  if (slackToken) {
    $('input[name=slackToken]').attr('value', slackToken);
  }
  var slackInstance = localStorage.getItem('slackInstance');
  if (slackInstance) {
    $('input[name=slackInstance]').attr('value', slackInstance);
  }
};

function saveSlackVars(context) {
  var localStoreStr = localStorage.getItem('teaas');
  if (!localStoreStr) {
    localStoreStr = "{}"
  }
  var localStore = JSON.parse(localStoreStr);

  var slackInstance = $(context.parentElement).find('input[name=slackInstance]')[0].value;
  var slackToken = $(context.parentElement).find('input[name=slackToken]')[0].value;
  if (slackInstance && slackToken) {
    localStore[slackInstance] = slackToken;
  }

  localStorage.setItem('teaas', JSON.stringify(localStore));
};

function useSelectedSlack(context) {
  $('input[name=slackToken]').attr('value', context.value);
  $('input[name=slackInstance]').attr('value', context.options[context.selectedIndex].innerHTML);
};

$(document).ready(function() {
  $('.file-wrapper input[type=file]').bind('change focus click', fileInputs);
  retrieveSlackVars();
});
