/*
 * Modal
 *
 * Pico.css - https://picocss.com
 * Copyright 2019-2024 - Licensed under MIT
 *
 * https://codesandbox.io/embed/4mrnhq
 */

// Config
const isOpenClass = "modal-is-open";
const openingClass = "modal-is-opening";
const closingClass = "modal-is-closing";
const scrollbarWidthCssVar = "--pico-scrollbar-width";
const animationDuration = 400; // ms
let visibleModal = null;

// Toggle modal
const toggleModal = (event) => {
  event.preventDefault();
  const modal = document.getElementById(event.currentTarget.dataset.target);
  if (!modal) return;
  modal && (modal.open ? closeModal(modal) : openModal(modal));
};

// Open modal
const openModal = (modal) => {
  const { documentElement: html } = document;
  const scrollbarWidth = getScrollbarWidth();
  if (scrollbarWidth) {
    html.style.setProperty(scrollbarWidthCssVar, `${scrollbarWidth}px`);
  }
  html.classList.add(isOpenClass, openingClass);
  setTimeout(() => {
    visibleModal = modal;
    html.classList.remove(openingClass);
  }, animationDuration);
  modal.showModal();
};

// Close modal
const closeModal = (modal) => {
  visibleModal = null;
  const { documentElement: html } = document;
  html.classList.add(closingClass);
  setTimeout(() => {
    html.classList.remove(closingClass, isOpenClass);
    html.style.removeProperty(scrollbarWidthCssVar);
    modal.close();
  }, animationDuration);
};

// Close with a click outside
document.addEventListener("click", (event) => {
  if (visibleModal === null) return;
  const modalContent = visibleModal.querySelector("article");
  const isClickInside = modalContent.contains(event.target);
  !isClickInside && closeModal(visibleModal);
});

// Close with Esc key
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && visibleModal) {
    closeModal(visibleModal);
  }
});

// Get scrollbar width
const getScrollbarWidth = () => {
  const scrollbarWidth = window.innerWidth - document.documentElement.clientWidth;
  return scrollbarWidth;
};

// Is scrollbar visible
const isScrollbarVisible = () => {
  return document.body.scrollHeight > screen.height;
};



$( document ).ready(function() {
  
  $('.close_modal').on('click', function (e) {
    const $modal = $(this).closest('dialog');
    closeModal($modal[0]);
    $modal.find('input').val('');
    
  });
  
  $('message_modal').on('close', function (e) {
    $('#message_title_text').text('');
    $('#message_text').text('');
  });
  
  $('my_acct_modal').on('close', function (e) {
    $('#full_name').val('');
    $('#affiliation').val('');
  });
  
  $('forgot_pw_modal').on('close', function (e) {
    $('#forgot_pw_email').val('');
  });
  
  $('add_users_modal').on('close', function (e) {
    $('#emails').val('');
  });
  
});



const display_message = (title, msg) => {
  
  let color = '';
  
  if (title == 'success') {
    $('#message_title_text')
      .css('color', 'var(--pico-ins-color)')
      .html('<i class="fa fa-check" aria-hidden="true"></i> Success');
  }
  else if (title == 'error') {
    $('#message_title_text')
      .css('color', 'var(--pico-del-color)')
      .html('<i class="fa fa-times" aria-hidden="true"></i> Error');
  }
  else {
    $('#message_title_text')
      .css('color', '')
      .text(title);
  }
  
  $('#message_text').text(msg);
  openModal($('#message_modal')[0]);
};
