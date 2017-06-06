//
//  DDCollectionViewGridLayout.swift
//  Pods
//
//  Created by Mat Cegiela on 5/28/17.
//
//

import UIKit

public protocol DDCollectionViewDelegateGridLayout : UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    
    func collectionView(_ collectionView:UICollectionView, layout collectionViewLayout: UICollectionViewLayout, gridLayoutPositionFor indexPath: IndexPath) -> GridLayoutPosition
}

public struct GridLayoutPosition: Hashable {
    
    //Zero in either direction is interpreted as 'off the grid' and item is not shown
    //Top left corner is 1,1
    var x: Int = 0
    var y: Int = 0
    
    public init(x: Int = 0, y: Int = 0) {
        self.x = x
        self.y = y
    }
    
    public var hashValue: Int {
        return x.hashValue ^ y.hashValue
    }
    
    public static func == (lhs: GridLayoutPosition, rhs: GridLayoutPosition) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

public class DDCollectionViewGridLayout: UICollectionViewLayout {
    
    private var layoutAttributesByIndexPath = [IndexPath : UICollectionViewLayoutAttributes]()
    private var layoutPositionByIndexPath = [IndexPath : GridLayoutPosition]()
    private var gridLayoutBounds = GridLayoutPosition()
    
    private var widthsByPosition = [Int : CGFloat]()
    private var heightsByPosition = [Int : CGFloat]()

    private var totalLayoutSize = CGSize.zero
    
    public var paddingBetweenItems = CGSize(width: 8.0, height: 8.0)
    public var defaultItemSize = CGSize.zero
    
    public var layoutDelegate: DDCollectionViewDelegateGridLayout?
    
    override public var collectionViewContentSize: CGSize {
        return totalLayoutSize
    }
    
    override public func invalidateLayout() {
        layoutAttributesByIndexPath.removeAll()
        totalLayoutSize = CGSize()
        super.invalidateLayout()
    }
    
    override public func prepare() {
        calculateLayout()
        super.prepare()
    }
    
    private func calculateLayout() {
        if layoutAttributesByIndexPath.count == 0 {
            buildLayoutAttributes()
        }
        getItemPositionsAndSizes()
        calculateColumnAndRowSizes()
        calculateItemLayout()
    }
    
    private func buildLayoutAttributes() {
        if let collectionView = collectionView {
            
            //Create a layout attributes instance for each item in collection view
            layoutAttributesByIndexPath.removeAll()
            
            for section in 0..<collectionView.numberOfSections {
                for item in 0..<collectionView.numberOfItems(inSection: section) {
                    let indexPath = IndexPath(item: item, section: section)
                    let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                    layoutAttributesByIndexPath[indexPath] = attributes
                }
            }
        }
    }
    
    private func getItemPositionsAndSizes() {
        if let collectionView = collectionView, let delegate = layoutDelegate {
            
            //Get item positions and sizes
            for layoutItem in layoutAttributesByIndexPath.values {
                let layoutPosition = delegate.collectionView(collectionView, layout: self, gridLayoutPositionFor: layoutItem.indexPath)
                layoutPositionByIndexPath[layoutItem.indexPath] = layoutPosition
                
                layoutItem.size = delegate.collectionView(collectionView, layout: self, sizeForItemAt: layoutItem.indexPath)
                
                //TODO://////Check if position zero -- mark hidden
                if layoutPosition.x <= 0 || layoutPosition.y <= 0 {
                    //Item is not on the grid
                    layoutItem.isHidden = true
                } else {
                    layoutItem.isHidden = false
                }
            }
        }
    }
    
    private func calculateColumnAndRowSizes() {
        
        for layoutItem in layoutAttributesByIndexPath.values {
            
            let layoutPosition = layoutPositionByIndexPath[layoutItem.indexPath] ?? GridLayoutPosition()
            
            //Set the size for each column and row to accomodate largest item
            let newWidth = max((widthsByPosition[layoutPosition.x] ?? 0.0), layoutItem.size.width)
            widthsByPosition[layoutPosition.x] = newWidth
            let newHeight = max((heightsByPosition[layoutPosition.y] ?? 0.0), layoutItem.size.height)
            heightsByPosition[layoutPosition.y] = newHeight
            
            //Set layout bounds to find the furthermost item
            gridLayoutBounds.x = max(gridLayoutBounds.x, layoutPosition.x)
            gridLayoutBounds.y = max(gridLayoutBounds.y, layoutPosition.y)
        }
    }
    
    private func calculateItemLayout() {
        
        //Set up arrays of sizes for easier reference
        
        var columnWidths: [CGFloat] = [0.0] //First set to zero to match index with position
        var rowHeights: [CGFloat] = [0.0] //First set to zero to match index with position
        
        var paddingWidths: [CGFloat] = [paddingBetweenItems.width] //Outside padding
        var paddingHeights: [CGFloat] = [paddingBetweenItems.height] //Outside padding
        
        //Fill array of all column widths. Add in any blanks if needed.
        if gridLayoutBounds.x > 0 {
            for position in 1...gridLayoutBounds.x {
                let width = widthsByPosition[position] ?? defaultItemSize.width
                columnWidths.append(width)
                
                //Add padding
                let padding = width > 0.0 ? paddingBetweenItems.width : 0.0
                paddingWidths.append(padding)
            }
        }
        
        //Fill array of all row heights. Add in any blanks if needed
        if gridLayoutBounds.y > 0 {
            for position in 1...gridLayoutBounds.y {
                let height = heightsByPosition[position] ?? defaultItemSize.height
                rowHeights.append(height)
                
                //Add padding
                let padding = height > 0.0 ? paddingBetweenItems.height : 0.0
                paddingHeights.append(padding)
            }
        }
        
        //Calculate idividual item positions
        for layoutItem in layoutAttributesByIndexPath.values {
            
            if let position = layoutPositionByIndexPath[layoutItem.indexPath], layoutItem.isHidden == false {
                
                //Add up preceeding space and padding
                let leadingPaddingWidths = paddingWidths[0..<position.x].reduce(0, +)
                let leadingTotalWidth = columnWidths[0..<position.x].reduce(0, +) + leadingPaddingWidths
                
                let leadingPaddingHeights = paddingHeights[0..<position.y].reduce(0, +)
                let leadingTotalHeight = rowHeights[0..<position.y].reduce(0, +) + leadingPaddingHeights
                
                let centerX = leadingTotalWidth + columnWidths[position.x] / 2
                let centerY = leadingTotalHeight + rowHeights[position.y] / 2
                
                layoutItem.center = CGPoint(x: centerX, y: centerY)
                
            } else {
                
                //Place items below layout, so that they animate up
                let centerX = (columnWidths.reduce(0, +) + paddingWidths.reduce(0, +)) / 2
                let centerY = rowHeights.reduce(0, +) + paddingHeights.reduce(0, +) + 100
                
                layoutItem.center = CGPoint(x: centerX, y: centerY)
            }
        }
        
        //Calculate total layout size
        let totalWidth = columnWidths.reduce(0, +) + paddingWidths.reduce(0, +) + paddingBetweenItems.width
        let totalHeight = rowHeights.reduce(0, +) + paddingHeights.reduce(0, +) + paddingBetweenItems.height
        
        totalLayoutSize = CGSize(width: totalWidth, height: totalHeight)
    }
    
    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let item = layoutAttributesByIndexPath[indexPath]
        return item
    }
    
    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let items = Array(layoutAttributesByIndexPath.values).filter { (item) -> Bool in
            return item.frame.intersects(rect) && item.isHidden == false
        }
        return items
    }
    
    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        //If returning true a full recalculation will be triggered repeatedly during scrolling
        return false
    }
    
    override public func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        return context
    }
}
