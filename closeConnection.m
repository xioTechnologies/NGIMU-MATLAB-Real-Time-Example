function closeConnection(udpObject)
    fclose(udpObject);
    delete(udpObject);
end
