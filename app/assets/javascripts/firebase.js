// Initialize Firebase
let config = {
    apiKey: "AIzaSyAyn4L700DQny83ix5bbg13_amJLCEs6TU",
    authDomain: "raptor-fc7b8.firebaseapp.com",
    databaseURL: "https://raptor-fc7b8.firebaseio.com",
    projectId: "raptor-fc7b8",
    storageBucket: "raptor-fc7b8.appspot.com",
    messagingSenderId: "1028055780643"
};
firebase.initializeApp(config);
firebase.database();

list_id = $('#list_id').text();
let starCountRef = firebase.database().ref('SidekiqJob/' + list_id);
starCountRef.on('value', function(snapshot) {
    if(snapshot.val() !== null) {
        let progress_done = snapshot.val().status;
        $('.progress-bar-animated').attr('aria-valuenow', progress_done).css('width', progress_done+'%');
        if(progress_done === 100) {
            DataRequest(snapshot.val().process_id)
        }
    }
});

function DataRequest(process_id) {
    $.ajax({
        url: "homes",
        dataType: 'script',
        data: {
            id: window.location.href.replace(/.*id=/g, ''),
            process_id: process_id

        },
    });
};