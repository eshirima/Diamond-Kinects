import UIKit
import Foundation
import PlaygroundSupport

/****
The entirety of this solution was put together on Friday September 20, 2019.
A few tweaks were made to the original signature/design:
	1. A new measurement quantity (magnitude) is introduced on both the accelerometer and gyroscope datapoints
	2. The API signatures were changed to reflect the quantity addition. Magnitude is the defining quantity used to fulfill
	respective API requirements
	3. Assumes that the CSV file is stored in ~/../Documents/Shared Playground Data/

The above changes were made for ease of debugging and memory footprint reduction. Should you be totally against this, please feel free to reach out and the amendments will be promptly reverted.

Playgrounds was used for ease and proof of concept purposes. If this was a full fledged application, the MVC architecture would have been utilised. The respective structs and class would be part of the Model, and a View Controller used for manipulation and rendering to the View.

FUTURE RECOMMENDATIONS:
	1. If I was made aware of the scope of the project and more time, I would consider re-writing the API to utilise the Accelerate Framework using vector manipulations for speed-up.
****/

var DATA_FILENAME: String = "latestSwing.csv"

struct Accelerometer
{
	var x: Double = Double.nan
	var y: Double = Double.nan
	var z: Double = Double.nan
	
	var isEmpty: Bool { return x.isNaN || y.isNaN || z.isNaN }
	
	var magnitude: Double
	{
		if !isEmpty
		{
			return sqrt(pow(x, 2) + pow(y, 2) + pow(z, 2))
		}
		else { return Double.nan }
	}
}

struct Gyroscope
{
	var x: Double = Double.nan
	var y: Double = Double.nan
	var z: Double = Double.nan
	
	var isEmpty: Bool { return x.isNaN || y.isNaN || z.isNaN }
	
	var magnitude: Double
	{
		if !isEmpty
		{
			return sqrt(pow(x, 2) + pow(y, 2) + pow(z, 2))
		}
		else { return Double.nan }
	}
}

struct Reading
{
	var timeStamp: Int = Int.min
	var accelerometer: Accelerometer = Accelerometer()
	var gyroscope: Gyroscope = Gyroscope()
	
	var isEmpty: Bool { return timeStamp == Int.min || gyroscope.isEmpty || accelerometer.isEmpty }
}

// MARK: Responsible for extracting contents of CSV file
struct FileParser
{
	func readDataFromCSV(fileURL: URL)->[Reading]
	{
		do
		{
			let contents = try String(contentsOf: fileURL, encoding: String.Encoding.utf8)
			return parseStringToArray(content: contents)
		} catch let error
		{
			assertionFailure(error.localizedDescription)
			return []
		}
	}
	
	private func parseStringToArray(content: String)->[Reading]
	{
		// string clean-up
		var data = content.components(separatedBy: ["\n", ",", "\r"])
		data.removeAll { $0 == "" }
		
		var readings: [Reading] = []
		
		var index = 0
		
		while index < data.count
		{
			guard let timestamp = Int(data[index]) else
			{
				assertionFailure("Timestamp issue")
				return []
			}
			
			// handle accelerometer information
			guard let accX = Double(data[index + 1]), let accY = Double(data[index + 2]), let accZ = Double(data[index + 3]) else
			{
				assertionFailure("Problem with accelerometer data")
				return []
			}
			
			// handle gyroscope information
			guard let gyroX = Double(data[index + 4]), let gyroY = Double(data[index + 5]), let gyroZ = Double(data[index + 6]) else
			{
				assertionFailure("Problem with gyroscope data")
				return []
			}
			
			readings.append(Reading(timeStamp: timestamp, accelerometer: Accelerometer(x: accX, y: accY, z: accZ), gyroscope: Gyroscope(x: gyroX, y: gyroY, z: gyroZ)))
			
			// skip to next data-point
			index += 7
		}
		
		return readings
	}
}

class Experiment
{
	fileprivate var readings: [Reading] = []
	
	// MARK: Constructors
	init() { readings = [] }
	
	init(point: Reading)
	{
		if !point.isEmpty { readings.append(point) }
	}
	
	init(points: [Reading])
	{
		if !points.isEmpty { readings = points }
	}
	
	func extractDataFrom(file: String)
	{
		if !file.isEmpty
		{
			let fileURL: URL = playgroundSharedDataDirectory.appendingPathComponent(file)
			
			if fileURL.pathExtension == "csv"
			{
				readings = FileParser().readDataFromCSV(fileURL: fileURL)
			}
			else { assertionFailure("Only CSV files are supported") }
		}
		else { assertionFailure("Empty filename") }
	}
	
	// uses either accelerometer or gyroscope magnitude data for calculations
	func searchContinuityAboveValue(indexBegin: Int, indexEnd: Int, threshold: Double, winLength: Int, isAccelerometerData: Bool = true)-> (found: Bool, index: Int)
	{
		let sanityCheckResults = forwardSanityCheck(indexBegin: indexBegin, indexEnd: indexEnd, winLength: winLength)
		
		if !sanityCheckResults.pass
		{
			assertionFailure(sanityCheckResults.message)
			return (false, Int.min)
		}
		
		var occurences: Int = 0
		var index: Int = indexBegin
		var firstIndex: Int = Int.min
		
		while index < indexEnd
		{
			var magnitude: Double = 0.0
			
			if isAccelerometerData { magnitude = readings[index].accelerometer.magnitude }
			else { magnitude = readings[index].gyroscope.magnitude }
			
			if magnitude > threshold
			{
				// first time meeting this criteria
				if firstIndex == Int.min { firstIndex = index }
				
				occurences += 1
				
				if occurences == winLength { break }
			}
			else
			{
				occurences = 0
				firstIndex = Int.min
			}
			
			index += 1
		}
		
		// handles the case when the last element(s)
		// meet(s) criteria but 'winLength' was not reached
		if occurences != winLength
		{
			occurences = 0
			firstIndex = Int.min
			return (false, firstIndex)
		}
		
		return (true, firstIndex)
	}
	
	func backSearchContinuityWithinRange(indexBegin: Int, indexEnd: Int, thresholdLo: Double, thresholdHi: Double, winLength: Int, isAccelerometerData: Bool = true)-> (found: Bool, index: Int)
	{
		// make sure everything is okay before execution
		let sanityCheckResults = backwardSanityCheck(indexBegin: indexBegin, indexEnd: indexEnd, thresholdLo: thresholdLo, thresholdHi: thresholdHi, winLength: winLength)
		
		if !sanityCheckResults.pass
		{
			assertionFailure(sanityCheckResults.message)
			return (false, Int.min)
		}
		
		var occurences: Int = 0
		var index: Int = indexBegin
		var firstIndex: Int = Int.min
		
		while index > indexEnd
		{
			var magnitude: Double = 0.0
			
			if isAccelerometerData { magnitude = readings[index].accelerometer.magnitude }
			else { magnitude = readings[index].gyroscope.magnitude }
			
			if magnitude > thresholdLo && magnitude < thresholdHi
			{
				// first time meeting criteria
				if firstIndex == Int.min { firstIndex = index }
				
				occurences += 1
				
				// requirement fulfilled
				if occurences == winLength { break }
			}
			else
			{
				// reset everything
				occurences = 0
				firstIndex = Int.min
			}
			
			index -= 1
		}
		
		// handles the case when the last element(s)
		// meet criteria but 'winLength' was not reached
		if occurences != winLength
		{
			occurences = 0
			firstIndex = Int.min
			return (false, firstIndex)
		}
		
		return (true, firstIndex)
	}
	
	// uses accelerometer and gyroscope data as data1 and data2 respectively
	func searchContinuityAboveValueTwoSignals(indexBegin: Int, indexEnd: Int, threshold1: Double, threshold2: Double, winLength: Int) -> [Int : (found: Bool, index: Int)]
	{
		var result = [Int: (found: Bool, index: Int)]()
		
		result[1] = searchContinuityAboveValue(indexBegin: indexBegin, indexEnd: indexEnd, threshold: threshold1, winLength: winLength)
		result[2] = searchContinuityAboveValue(indexBegin: indexBegin, indexEnd: indexEnd, threshold: threshold2, winLength: winLength, isAccelerometerData: false)
		
		return result
	}
	
	// similar implementation to 'searchContinuityAboveValue' but with an extra variable to keep track of the endIndex
	func searchMultiContinuityWithinRange(indexBegin: Int, indexEnd: Int, thresholdLo: Double, thresholdHi: Double, winLength: Int, isAccelerometerData: Bool)-> (found: Bool, indexStart: Int, indexEnd: Int)
	{
		let sanityCheckResult = forwardSanityCheck(indexBegin: indexBegin, indexEnd: indexEnd, winLength: winLength)
		
		if !sanityCheckResult.pass
		{
			assertionFailure(sanityCheckResult.message)
			return (false, Int.min, Int.min)
		}
		
		var occurences: Int = 0
		var index: Int = indexBegin
		var endIndex: Int = Int.min
		var firstIndex: Int = Int.min
		
		while index < indexEnd
		{
			var magnitude: Double = 0.0
			
			if isAccelerometerData { magnitude = readings[index].accelerometer.magnitude }
			else { magnitude = readings[index].gyroscope.magnitude }
			
			if magnitude > thresholdLo && magnitude < thresholdHi
			{
				// initial encounter
				if firstIndex == Int.min { firstIndex = index }
				
				occurences += 1
				
				if occurences == winLength
				{
					endIndex = index
					break
				}
			}
			else
			{
				occurences = 0
				firstIndex = Int.min
				endIndex = Int.min
			}
			
			index += 1
		}
		
		// edge case resolution
		if occurences != winLength
		{
			occurences = 0
			endIndex = Int.min
			firstIndex = Int.min
			return (false, firstIndex, endIndex)
		}
		
		return (true, firstIndex, endIndex)
	}
	
	func reset()
	{
		if !readings.isEmpty { readings.removeAll() }
	}
	
	// MARK: Sanity Checks
	
	// sanity check mutually performed on both forward and backward iteration methods
	private func standardChecks(indexBegin: Int, indexEnd: Int, winLength: Int, forward: Bool = true)-> (pass: Bool, message: String)
	{
		if indexBegin > readings.count || indexEnd > readings.count
		{
			return (false, "Invalid indices provided on array of \(readings.count) elements")
		}
		
		// if zero, then operation is similar to finding element
		if winLength < 0 { return (false, "Invalid window length") }
		
		if forward
		{
			if indexEnd - indexBegin < winLength { return (false, "Invalid Range") }
		}
		else
		{
			if indexBegin - indexEnd < winLength { return (false, "Invalid Range") }
		}
		
		return (true, "")
	}
	
	private func forwardSanityCheck(indexBegin: Int, indexEnd: Int, winLength: Int)-> (pass: Bool, message: String)
	{
		let standardCheckResults = standardChecks(indexBegin: indexBegin, indexEnd: indexEnd, winLength: winLength)
		
		if !standardCheckResults.pass { return standardCheckResults }
		
		if indexBegin > indexEnd { return (false, "End index cannot be smaller than begin index") }
		
		return (true, "")
	}
	
	private func backwardSanityCheck(indexBegin: Int, indexEnd: Int, thresholdLo: Double, thresholdHi: Double, winLength: Int)-> (pass: Bool, message: String)
	{
		let standardCheckResults = standardChecks(indexBegin: indexBegin, indexEnd: indexEnd, winLength: winLength, forward: false)
		
		if !standardCheckResults.pass { return standardCheckResults }
		
		if indexEnd > indexBegin { return (false, "End index cannot be larger than begin index") }
		
		if thresholdLo > thresholdHi { return (false, "Invalid Thresholds") }
		
		return (true, "")
	}
}

// USAGE
let experiment = Experiment()
experiment.extractDataFrom(file: DATA_FILENAME)

var result = experiment.searchContinuityAboveValue(indexBegin: 0, indexEnd: 10, threshold: 1.5, winLength: 5)
print(result)

result = experiment.backSearchContinuityWithinRange(indexBegin: 10, indexEnd: 2, thresholdLo: 0.5, thresholdHi: 1.6, winLength: 5)
print(result)
