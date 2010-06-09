if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      Mongoid.master.connection.connect_to_master
    end
  end
end

Mongoid.database.eval(
  <<-JAVASCRIPT
  db.system.js.save( { _id : 'contains', value : function( array, value ) {
    a = false;
    for(i = 0; i < array.length; i++) {
      if(array[i] == value) {
        a = true;
      }
    }
    return a;
  } } );
  JAVASCRIPT
)
