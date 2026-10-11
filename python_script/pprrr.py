import serial
import time

# Configuration
PORT = 'COM3'
BAUD_RATE = 115200  # Ensure this matches your device settings
OUTPUT_FILE = "serial_log.txt"

def listen_to_serial():
    try:
        # Initialize serial connection
        # timeout=1 ensures the script doesn't hang forever if no data comes in
        ser = serial.Serial(PORT, BAUD_RATE, timeout=1)
        print(f"Connected to {PORT} at {BAUD_RATE} baud.")
        print(f"Saving data to {OUTPUT_FILE}. Press Ctrl+C to stop.")

        with open(OUTPUT_FILE, "a") as f:
            while True:
                if ser.in_waiting > 0:
                    # Read a line of data
                    line = ser.readline().decode('utf-8').rstrip()
                    
                    if line:
                        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
                        data_entry = f"[{timestamp}] {line}"
                        
                        # Print to console
                        print(data_entry)
                        
                        # Write to file
                        f.write(data_entry + "\n")
                        f.flush()  # Force write to disk immediately

                time.sleep(0.01)  # Small delay to prevent high CPU usage

    except serial.SerialException as e:
        print(f"Error: Could not open serial port {PORT}. {e}")
    except KeyboardInterrupt:
        print("\nStopping script...")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print("Serial port closed.")

if __name__ == "__main__":
    listen_to_serial()