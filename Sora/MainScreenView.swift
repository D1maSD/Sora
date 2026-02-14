//
//  MainScreenView.swift
//  Sora
//
//  Created by Dima Melnik on 2/12/26.
//

import SwiftUI

// Модель сообщения
struct Message: Identifiable {
    let id = UUID()
    let text: String
    let image: UIImage?
    var isIncoming: Bool // true = входящее (от Sora), false = исходящее (от пользователя)
}

// Компонент для отображения исходящего сообщения
struct MessageView: View {
    let message: Message
    let maxWidth: CGFloat
    let onCopy: () -> Void
    let onDelete: () -> Void
    let onImageTap: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Фото сверху (если есть)
            if let image = message.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(25)
                    .padding(.top, 25)
                    .padding(.horizontal, 25)
                    .onTapGesture {
                        onImageTap?()
                    }
            }
            
            // Текст ниже фото
            if !message.text.isEmpty {
                Text(message.text)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, message.image != nil ? 25 : 16)
                    .padding(.vertical, message.image != nil ? 12 : 16)
                    .frame(maxWidth: message.image != nil ? .infinity : nil, alignment: .leading)
                    .fixedSize(horizontal: message.image == nil, vertical: false)
            }
            
            // HStack с кнопками внизу
            HStack(spacing: 5) {
                if message.image == nil {
                    Spacer(minLength: 0)
                } else {
                    Spacer()
                }
                
                // Кнопка copy
                Button(action: onCopy) {
                    Image("copy")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 29, height: 29)
                        .foregroundColor(.white)
                }
                
                // Кнопка trash
                Button(action: onDelete) {
                    Image("trash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 29, height: 29)
                        .foregroundColor(.white)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            .padding(.top, (message.text.isEmpty && message.image != nil) ? 12 : 0)
            .padding(.leading, message.image == nil ? 16 : 0)
        }
        .background(Color(hex: "#1F2023"))
        .cornerRadius(40)
        .frame(maxWidth: message.image != nil ? maxWidth : nil)
        .fixedSize(horizontal: message.image == nil, vertical: false)
        .frame(maxWidth: maxWidth, alignment: .trailing)
    }
}

// Компонент для отображения входящего сообщения (от Sora)
struct IncomingMessageView: View {
    let message: Message
    let maxWidth: CGFloat
    let onTrash: () -> Void
    let onDownload: () -> Void
    let onShare: () -> Void
    let onRefresh: () -> Void
    let onImageTap: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Фото сверху (если есть)
            if let image = message.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(25)
                    .padding(.top, 25)
                    .padding(.horizontal, 25)
                    .onTapGesture {
                        onImageTap?()
                    }
            }
            
            // Текст ниже фото
            if !message.text.isEmpty {
                Text(message.text)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, message.image != nil ? 25 : 16)
                    .padding(.vertical, message.image != nil ? 12 : 16)
                    .frame(maxWidth: message.image != nil ? .infinity : nil, alignment: .leading)
                    .fixedSize(horizontal: message.image == nil, vertical: false)
            }
            
            // HStack с кнопками внизу
            HStack(spacing: 5) {
                if message.image == nil {
                    Spacer(minLength: 0)
                } else {
                    Spacer()
                }
                
                // Кнопка trash
                Button(action: onTrash) {
                    Image("trash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 29, height: 29)
                        .foregroundColor(.white)
                }
                
                // Кнопка download
                Button(action: onDownload) {
                    Image("download")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 29, height: 29)
                        .foregroundColor(.white)
                }
                
                // Кнопка share
                Button(action: onShare) {
                    Image("share")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 29, height: 29)
                        .foregroundColor(.white)
                }
                
                // Spacer между share и refresh
                Spacer()
                
                // Кнопка refresh
                Button(action: onRefresh) {
                    Image("refresh")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 29, height: 29)
                        .foregroundColor(.white)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            .padding(.top, (message.text.isEmpty && message.image != nil) ? 12 : 0)
            .padding(.leading, message.image == nil ? 16 : 0)
        }
        .background(Color(hex: "#1F2023"))
        .cornerRadius(40)
        .frame(maxWidth: message.image != nil ? maxWidth : nil)
        .fixedSize(horizontal: message.image == nil, vertical: false)
        .frame(maxWidth: maxWidth, alignment: .leading)
    }
}

// Расширение для скругления только определенных углов
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct MainScreenView: View {
    @State private var chatEffectsSelection = 0 // 0 = chat, 1 = effects
    @State private var photoVideoSelection = 0 // 0 = photo, 1 = video
    @State private var textFieldText = ""
    @State private var showAddPhotoSheet = false
    @State private var selectedImage: UIImage? = nil
    @State private var imageFileName: String = ""
    @State private var isLoadingImage: Bool = false
    @State private var messages: [Message] = []
    @State private var isLoadingResponse: Bool = false
    @State private var showStyleSheet = false
    @State private var selectedStyle: Int? = nil
    @State private var selectedStyleName: String? = nil // Сохраняем название выбранного стиля
    @State private var showImageViewer = false
    @State private var imageToView: UIImage? = nil
    
    var body: some View {
        ZStack {
            // Фоновое изображение
            Image("phone")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                topSection
                messagesSection
                bottomSection
            }
        }
    }
    
    // Верхняя часть с свитчерами и кнопками
    private var topSection: some View {
        VStack(spacing: 8) {
            firstRow
            secondRow
        }
    }
    
    // Первый ряд: chat/effects свитчер, кнопка +, градиентная кнопка 1000
    private var firstRow: some View {
        GeometryReader { geometry in
            let switchWidth: CGFloat = 175
            let switchPadding: CGFloat = 8
            let totalSwitchWidth = switchWidth + (switchPadding * 2)
            let sidePadding: CGFloat = 40
            let spacingBetweenElements: CGFloat = 4
            
            // Вычисляем ширину градиентной кнопки 1000
            let gradientButtonContentWidth: CGFloat = 50 + 8 + 32 // текст "1000" (~50) + spacing (8) + иконка (32)
            let gradientButtonPadding: CGFloat = 16 * 2 // padding horizontal
            let gradientButtonWidth = gradientButtonContentWidth + gradientButtonPadding
            
            // Вычисляем ширину кнопки +
            let totalSpacing = spacingBetweenElements * 2 // 2 отступа между 3 элементами
            let availableWidth = geometry.size.width - (sidePadding * 2) - totalSwitchWidth - gradientButtonWidth - totalSpacing
            let plusButtonWidth = availableWidth
            
            HStack(alignment: .center, spacing: 2) {
                // Свитчер chat/effects в контейнере
                CustomSwitch(
                    options: ["chat", "effects"],
                    selection: $chatEffectsSelection
                )
                .frame(width: switchWidth)
                .padding(switchPadding)
                .background(Color(hex: "#1F2023"))
                .cornerRadius(12)
                
                // Кнопка +
                Button(action: {}) {
                    Image("plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.white)
                }
                .frame(width: plusButtonWidth + 25, height: 51)
                .background(Color(hex: "#1F2023"))
                .cornerRadius(12)
                .padding(.leading, 2)
                
                // Градиентная кнопка 1000
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Text("1000")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.white)
                        
                        Image("sparkles")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#6CABE9"),
                                Color(hex: "#2F76BC")
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .frame(width: gradientButtonWidth - 17, height: 42)
            }
            .padding(.leading, sidePadding)
            .padding(.trailing, sidePadding)
        }
        .frame(height: 71)
        .padding(.top, 20)
    }
    
    // Второй ряд: photo/video свитчер слева, кнопки справа
    private var secondRow: some View {
        GeometryReader { geometry in
            let switchWidth: CGFloat = 155
            let switchPadding: CGFloat = 8
            let totalSwitchWidth = switchWidth + (switchPadding * 2)
            let sidePadding: CGFloat = 40
            let spacingBetweenButtons: CGFloat = 4
            let totalSpacing = spacingBetweenButtons * 3 // 3 отступа между 4 элементами
            let availableWidth = geometry.size.width - (sidePadding * 2) - totalSwitchWidth - totalSpacing
            let buttonWidth = availableWidth / 3
            
            HStack(alignment: .center, spacing: spacingBetweenButtons) {
                // Свитчер photo/video
                CustomSwitch(
                    options: ["photo", "video"],
                    selection: $photoVideoSelection
                )
                .frame(width: switchWidth)
                .padding(switchPadding)
                .background(Color(hex: "#1F2023"))
                .cornerRadius(12)
                
                // Кнопки: plus, clockArrow, trash
                
                Button(action: {}) {
                    Image("trash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.white)
                }
                .frame(width: buttonWidth, height: 51)
                .background(Color(hex: "#1F2023"))
                .cornerRadius(12)
                Button(action: {}) {
                    Image("clockArrow")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.white)
                }
                .frame(width: buttonWidth, height: 51)
                .background(Color(hex: "#1F2023"))
                .cornerRadius(12)
                
                Button(action: {}) {
                    Image("plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.white)
                }
                .frame(width: buttonWidth, height: 51)
                .background(Color(hex: "#1F2023"))
                .cornerRadius(12)
            }
            .padding(.leading, sidePadding)
            .padding(.trailing, sidePadding)
        }
        .frame(height: 71)
    }
    
    
    // Область для отображения сообщений
    private var messagesSection: some View {
        GeometryReader { geometry in
            MessagesListView(
                messages: messages,
                isLoadingResponse: isLoadingResponse,
                imageToView: $imageToView,
                showImageViewer: $showImageViewer,
                onDeleteMessage: { id in
                    messages.removeAll { $0.id == id }
                },
                geometry: geometry
            )
        }
    }
    // Нижняя часть с TextField и кнопками
    private var bottomSection: some View {
        VStack(spacing: 2) {
            textFieldContainer
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
        .sheet(isPresented: $showAddPhotoSheet) {
            AddPhotoBottomSheet(selectedImage: $selectedImage)
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $showStyleSheet) {
            StyleBottomSheet(
                selectedStyle: $selectedStyle,
                selectedStyleName: $selectedStyleName
            )
            .presentationDetents([.fraction(0.65)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            if let image = imageToView {
                ImageViewer(image: image)
            }
        }
        .onChange(of: selectedImage) { newImage in
            if newImage != nil {
                isLoadingImage = true
                imageFileName = "photo_\(Int(Date().timeIntervalSince1970)).jpg"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isLoadingImage = false
                }
            } else {
                imageFileName = ""
                isLoadingImage = false
            }
        }
    }
    
    // Контейнер для TextField
    private var textFieldContainer: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                            // TextField
                            TextField("", text: $textFieldText, prompt: Text("Type here").foregroundColor(.white))
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.clear)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.clear, lineWidth: 0)
                                )
                            
                            // Превью изображения под TextField
                            if selectedImage != nil || isLoadingImage {
                                HStack(spacing: 12) {
//                                    Spacer()
                                    
                                    if let image = selectedImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .clipped()
                                            .cornerRadius(8)
                                    }
                                    
                                    if !imageFileName.isEmpty {
                                        Text(imageFileName)
                                            .font(.system(size: 15, weight: .regular))
                                            .foregroundColor(.white)
                                    }
                                    
                                    if isLoadingImage {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .frame(width: 25, height: 25)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .padding(.horizontal, 16)
                                .padding(.top, 2)
                                .padding(.bottom, 8)
                            }
                            
                            // Кнопки внизу - прикреплены к левому краю
                            HStack(spacing: 4) {
                                // Кнопка с плюсом слева
                                Button(action: {
                                    showAddPhotoSheet = true
                                }) {
                                    Image("plus")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.white)
                                        .frame(width: 46, height: 44)
                                        .background(Color(hex: "#3B3D40"))
                                        .cornerRadius(12)
                                }
                                
                                // Кнопка Style/720px справа
                                if photoVideoSelection == 0 {
                                    // photo выбран - показываем Style или выбранный стиль
                                    Button(action: {
                                        if selectedStyleName != nil {
                                            // Сброс состояния при нажатии на xmark
                                            selectedStyle = nil
                                            selectedStyleName = nil
                                        } else {
                                            // Открытие BottomSheet
                                            showStyleSheet = true
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Text(selectedStyleName ?? "Style")
                                                .font(.system(size: 17, weight: .regular))
                                                .foregroundColor(selectedStyleName != nil ? Color(hex: "#2F76BC") : .white)
                                            
                                            if selectedStyleName != nil {
                                                Image("xmark")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 24, height: 24)
                                                    .foregroundColor(Color.white)
                                            } else {
                                                Image("plus")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 24, height: 24)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .frame(height: 44)
                                        .padding(.horizontal, 12)
                                        .background(Color(hex: "#3B3D40"))
                                        .cornerRadius(12)
                                    }
                                } else {
                                    // video выбран - показываем 720px
                                    Button(action: {}) {
                                        Text("720px")
                                            .font(.system(size: 17, weight: .regular))
                                            .foregroundColor(.white)
                                            .frame(width: 75, height: 44)
                                            .background(Color(hex: "#3B3D40"))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Текст "Cost of generation: 10 tokens"
                            HStack {
                                Text("Cost of generation: ")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text("10 tokens")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(13)
                        .background(Color(hex: "#1F2023"))
                        .cornerRadius(16)
                        
                        // Кнопка top_arrow - появляется когда есть текст
                        if !textFieldText.isEmpty {
                            Button(action: {
                                // Сохраняем данные перед очисткой
                                let messageText = textFieldText
                                let messageImage = selectedImage
                                
                                // Создание нового исходящего сообщения
                                let newMessage = Message(
                                    text: messageText,
                                    image: messageImage,
                                    isIncoming: false
                                )
                                messages.append(newMessage)
                                
                                // Очистка полей
                                textFieldText = ""
                                selectedImage = nil
                                imageFileName = ""
                                
                                // Показываем loading
                                isLoadingResponse = true
                                
                                // Через 2 секунды скрываем loading и показываем входящее сообщение
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    isLoadingResponse = false
                                    
                                    // Создаем входящее сообщение
                                    let incomingMessage = Message(
                                        text: "Mock output image",
                                        image: UIImage(named: "fiveScreen"),
                                        isIncoming: true
                                    )
                                    messages.append(incomingMessage)
                                }
                            }) {
                                Image("top_arrow")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(.black)
                                    .frame(width: 48, height: 48)
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 20)
                            .padding(.trailing, 20)
            }
        }
    }
    
}


// Отдельный View для списка сообщений
struct MessagesListView: View {
    let messages: [Message]
    let isLoadingResponse: Bool
    @Binding var imageToView: UIImage?
    @Binding var showImageViewer: Bool
    let onDeleteMessage: (UUID) -> Void
    let geometry: GeometryProxy
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(messages) { message in
                    if message.isIncoming {
                                    // Входящее сообщение (слева)
                                    HStack {
                                        IncomingMessageView(
                                            message: message,
                                            maxWidth: geometry.size.width * 0.6,
                                            onTrash: {
                                                // Удаление сообщения
                                                onDeleteMessage(message.id)
                                            },
                                            onDownload: {
                                                // Скачивание
                                                // TODO: Реализовать скачивание
                                            },
                                            onShare: {
                                                // Поделиться
                                                // TODO: Реализовать шаринг
                                            },
                                            onRefresh: {
                                                // Обновить
                                                // TODO: Реализовать обновление
                                            },
                                            onImageTap: {
                                                if let image = message.image {
                                                    imageToView = image
                                                    showImageViewer = true
                                                }
                                            }
                                        )
                                        Spacer()
                                    }
                                    .padding(.horizontal, 40)
                                } else {
                                    // Исходящее сообщение (справа)
                                    HStack {
                                        Spacer()
                                        MessageView(
                                            message: message,
                                            maxWidth: geometry.size.width * 0.6,
                                            onCopy: {
                                                // Копирование текста в буфер обмена
                                                UIPasteboard.general.string = message.text
                                            },
                                            onDelete: {
                                                // Удаление сообщения
                                                onDeleteMessage(message.id)
                                            },
                                            onImageTap: {
                                                if let image = message.image {
                                                    imageToView = image
                                                    showImageViewer = true
                                                }
                                            }
                                        )
                                    }
                                    .padding(.horizontal, 40)
                                }
                            }
                            
                            // Loading view
                            if isLoadingResponse {
                                HStack {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color(hex: "#1F2023"))
                                            .frame(width: 72, height: 72)
                                        
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .frame(width: 32, height: 32)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 40)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                }
    
    
   
    
}

struct CustomSwitch: View {
    let options: [String]
    @Binding var selection: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Фон свитчера (невидимый, так как контейнер уже есть снаружи)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.clear)
                    .frame(height: 35)
                
                // Белая область для активного элемента с увеличенным скруглением
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(width: geometry.size.width / CGFloat(options.count), height: 31)
                    .offset(x: CGFloat(selection) * (geometry.size.width / CGFloat(options.count)), y: 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selection)
            }
            .overlay(
                HStack(spacing: 0) {
                    ForEach(0..<options.count, id: \.self) { index in
                        Button(action: {
                            withAnimation {
                                selection = index
                            }
                        }) {
                            Text(options[index])
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(selection == index ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 35)
                        }
                    }
                }
            )
        }
        .frame(height: 35)
    }
}

// BottomSheet для выбора стиля
struct StyleBottomSheet: View {
    @Binding var selectedStyle: Int?
    @Binding var selectedStyleName: String?
    @Environment(\.dismiss) var dismiss
    
    let styles = [
        ("Style01", "Anime"),
        ("Style02", "Cyberpunk"),
        ("Style03", "Pixel Art"),
        ("Style04", "Fantasy"),
        ("Style05", "Disney"),
        ("Style06", "Cartoon"),
        ("Style07", "Pokémon"),
        ("Style08", "Lego"),
        ("Style09", "Avatar 3D")
    ]
    
    var body: some View {
        ZStack {
            Color(hex: "#0D0D0F")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Сетка карточек 3x3
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(0..<styles.count, id: \.self) { index in
                            StyleCard(
                                imageName: styles[index].0,
                                title: styles[index].1,
                                isSelected: selectedStyle == index,
                                onTap: {
                                    selectedStyle = index
                                    selectedStyleName = styles[index].1
                                    dismiss()
                                }
                            )
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                }
                
                // Кнопка Done
                Button(action: {
                    dismiss()
                }) {
                    Text("Done")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#6CABE9"),
                                    Color(hex: "#2F76BC")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 50)
            }
        }
    }
}

// Карточка стиля
struct StyleCard: View {
    let imageName: String
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        // Изображение с тайтлом внутри и внутренней обводкой
        ZStack(alignment: .bottomLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: .infinity, height: 100)
                .clipped()
                .cornerRadius(12)
            
            // Внутренняя обводка
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(hex: "#2F76BC"), lineWidth: 6)
                    .frame(width: .infinity, height: 100)
            }
            
            // Тайтл внутри изображения, прижат к нижнему краю, выровнен по центру
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(title)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    Spacer()
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.black.opacity(0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .frame(height: 100)
        .onTapGesture {
            onTap()
        }
    }
}

// Экран просмотра фото
struct ImageViewer: View {
    let image: UIImage
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Фоновое изображение
            Image("phone")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Навбар
                HStack {
                    // Кнопка назад
                    Button(action: {
                        dismiss()
                    }) {
                        Image("chevronLeft")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                    }
                    
                    Spacer()
                    
                    // Тайтл
                    Text("Result")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Кнопка threeDots
                    Button(action: {
                        // Пока без действия
                    }) {
                        Image("threeDots")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Контент
                VStack(spacing: 0) {
                    // Картинка
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(.top, 40)
                        .padding(.horizontal, 20)
                    
                    // Кнопка Share
                    Button(action: {
                        // TODO: Реализовать шаринг
                    }) {
                        Text("Share")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#6CABE9"),
                                        Color(hex: "#2F76BC")
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    MainScreenView()
}
